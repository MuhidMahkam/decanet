<?php
declare(strict_types=1);
require_once __DIR__ . '/../bin/bootstrap.php'; // должен инициализировать либо $APP_PDO, либо $GDB

function db_call_proc(string $proc, array $params = []): array
{
    // prefer PDO if available
    if (isset($GLOBALS['APP_PDO']) && $GLOBALS['APP_PDO'] instanceof \App\Database\PdoDb) {
        return $GLOBALS['APP_PDO']->callProcedure($proc, $params);
    }

    // fallback to old mysqli-based global $GDB
    global $GDB;
    if (isset($GDB) && $GDB instanceof \mysqli) {
        // build CALL with ?s and use prepared statements
        $placeholders = implode(',', array_fill(0, count($params), '?'));
        $sql = $placeholders === '' ? "CALL {$proc}()" : "CALL {$proc}({$placeholders})";
        $stmt = $GDB->prepare($sql);
        if ($stmt === false) {
            throw new \RuntimeException('Prepare failed: ' . $GDB->error);
        }
        if (!empty($params)) {
            $types = str_repeat('s', count($params));
            $stmt->bind_param($types, ...array_values($params));
        }
        $stmt->execute();
        $res = $stmt->get_result();
        $rows = $res ? $res->fetch_all(MYSQLI_ASSOC) : [];
        while ($GDB->more_results() && $GDB->next_result()) {
            $extra = $GDB->use_result();
            if ($extra instanceof \mysqli_result) { $extra->free(); }
        }
        return $rows;
    }

    throw new \RuntimeException('No DB connection available');
}
