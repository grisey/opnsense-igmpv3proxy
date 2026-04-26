<?php

namespace OPNsense\Igmpv3proxy;

class IndexController extends \OPNsense\Base\IndexController
{
    public function indexAction()
    {
        $this->response->redirect('/ui/igmpv3proxy/settings');
    }
}
