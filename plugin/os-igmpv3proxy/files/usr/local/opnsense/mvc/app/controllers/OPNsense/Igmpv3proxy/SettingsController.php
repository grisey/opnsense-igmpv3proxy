<?php

namespace OPNsense\Igmpv3proxy;

class SettingsController extends \OPNsense\Base\IndexController
{
    public function indexAction()
    {
        $this->view->title = gettext("Services: IGMPv3 Proxy: Settings");
        $this->view->general = $this->getForm("general");
        $this->view->pick('OPNsense/Igmpv3proxy/index');
    }
}
