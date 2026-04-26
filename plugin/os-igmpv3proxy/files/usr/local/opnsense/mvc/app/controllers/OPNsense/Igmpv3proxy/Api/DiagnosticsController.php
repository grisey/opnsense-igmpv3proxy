<?php

namespace OPNsense\Igmpv3proxy\Api;

use OPNsense\Base\ApiControllerBase;

class DiagnosticsController extends ApiControllerBase
{
    private function runCommand($command)
    {
        $backend = new \OPNsense\Core\Backend();
        $response = trim($backend->configdRun($command));
        return array("status" => "ok", "response" => $response);
    }

    public function configAction()
    {
        $path = "/usr/local/etc/igmpv3proxy.conf";
        if (file_exists($path)) {
            return array("status" => "ok", "response" => file_get_contents($path));
        }
        return array("status" => "ok", "response" => "");
    }

    public function routesAction()
    {
        return $this->runCommand("igmpv3proxy routes");
    }

    public function interfacesAction()
    {
        return $this->runCommand("igmpv3proxy interfaces");
    }

    public function filtersAction()
    {
        return $this->runCommand("igmpv3proxy filters");
    }
}
