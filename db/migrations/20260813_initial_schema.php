<?php

use Phinx\Migration\AbstractMigration;

class InitialSchema extends AbstractMigration
{
    public function change(): void
    {
        // Example migration: create dc_version table; replace/add real migrations after
        $table = $this->table('dc_version', ['id' => 'id']);
        $table->addColumn('version', 'string', ['limit' => 64])
              ->addColumn('applied_at', 'timestamp', ['default' => 'CURRENT_TIMESTAMP'])
              ->create();
    }
}
?>
