<?php

declare(strict_types=1);

namespace Decanet\Security;

use Closure;

final class SessionAuthorizer
{
    private Closure $clock;

    public function __construct(
        private readonly int $timeout = 900,
        ?Closure $clock = null,
    ) {
        $this->clock = $clock ?? static fn (): int => time();
    }

    /** @param array<string, mixed> $session */
    public function authorize(array &$session): bool
    {
        if (!isset($session['du_id'])) {
            return false;
        }

        $now = ($this->clock)();
        if (!isset($session['expire']) || $now > (int) $session['expire']) {
            $session['expired_du_id'] = $session['du_id'];
            unset($session['du_id']);

            return false;
        }

        $session['expire'] = $now + $this->timeout;

        return true;
    }
}
