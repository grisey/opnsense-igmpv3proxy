<?php

namespace OPNsense\Igmpv3proxy\Api;

use OPNsense\Base\ApiControllerBase;

class AliasesController extends ApiControllerBase
{
    private function isIPv4NetworkOrHost($item)
    {
        $item = trim($item);
        if ($item === '' || strpos($item, ':') !== false || strpos($item, '!') === 0) {
            return false;
        }

        if (strpos($item, '/') === false) {
            return filter_var($item, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) !== false;
        }

        $parts = explode('/', $item, 2);
        if (count($parts) !== 2) {
            return false;
        }

        if (filter_var($parts[0], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) === false) {
            return false;
        }

        if (!ctype_digit($parts[1])) {
            return false;
        }

        $mask = (int)$parts[1];
        return $mask >= 0 && $mask <= 32;
    }

    private function isMulticastIPv4($item)
    {
        $ip = explode('/', trim($item), 2)[0];
        if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) === false) {
            return false;
        }

        $addr = ip2long($ip);
        if ($addr === false) {
            return false;
        }

        $addr = (float)sprintf('%u', $addr);
        $start = (float)sprintf('%u', ip2long('224.0.0.0'));
        $end = (float)sprintf('%u', ip2long('239.255.255.255'));

        return $addr >= $start && $addr <= $end;
    }

    private function aliasesByMode($wantMulticast)
    {
        $result = array();
        $config = simplexml_load_file('/conf/config.xml');

        if ($config !== false) {
            foreach ($config->xpath('//aliases/alias') as $alias) {
                $name = trim((string)$alias->name);
                $type = trim((string)$alias->type);
                $content = trim((string)$alias->content);
                $enabled = trim((string)$alias->enabled);

                if ($name === '' || $content === '') {
                    continue;
                }

                if ($enabled !== '' && $enabled !== '1') {
                    continue;
                }

                if ($type !== 'network') {
                    continue;
                }

                $items = preg_split('/[\s,]+/', $content);
                $valid = true;

                foreach ($items as $item) {
                    if ($item === '') {
                        continue;
                    }

                    if (!$this->isIPv4NetworkOrHost($item)) {
                        $valid = false;
                        break;
                    }

                    if ($this->isMulticastIPv4($item) !== $wantMulticast) {
                        $valid = false;
                        break;
                    }
                }

                if ($valid) {
                    $result[$name] = $name;
                }
            }
        }

        ksort($result, SORT_NATURAL | SORT_FLAG_CASE);

        return array(
            'status' => 'ok',
            'aliases' => $result
        );
    }

    public function sourceAction()
    {
        return $this->aliasesByMode(false);
    }

    public function multicastAction()
    {
        return $this->aliasesByMode(true);
    }
}
