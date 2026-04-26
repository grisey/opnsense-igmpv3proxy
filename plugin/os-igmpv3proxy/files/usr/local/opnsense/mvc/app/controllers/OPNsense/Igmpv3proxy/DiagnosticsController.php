<?php

namespace OPNsense\Igmpv3proxy;

class DiagnosticsController extends \OPNsense\Base\IndexController
{
    public function indexAction()
    {
        $this->view->title = gettext("Services: IGMPv3 Proxy: Diagnostics");
        $this->view->pick('OPNsense/Igmpv3proxy/diagnostics');
    }
}
