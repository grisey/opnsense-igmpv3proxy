<?php

namespace OPNsense\Igmpv3proxy\Api;

use OPNsense\Base\ApiMutableServiceControllerBase;

class ServiceController extends ApiMutableServiceControllerBase
{
    protected static $internalServiceClass = '\OPNsense\Igmpv3proxy\Igmpv3proxy';
    protected static $internalServiceEnabled = 'enabled';
    protected static $internalServiceName = 'igmpv3proxy';
}
