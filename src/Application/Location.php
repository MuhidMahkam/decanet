<?php

declare(strict_types=1);

namespace Decanet\Application;

final readonly class Location
{
    public function __construct(
        public int $id,
        public string $name,
        public ?string $shortName = null,
    ) {
    }
}
