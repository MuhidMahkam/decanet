<?php

use Phinx\Seed\AbstractSeed;

class InitialSeed extends AbstractSeed
{
    public function run(): void
    {
        $data = [
            ['version' => 'initial-placeholder']
        ];

        $this->table('dc_version')->insert($data)->saveData();
    }
}
?>