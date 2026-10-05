<?php

declare(strict_types=1);

namespace Decanet\Security;

use RuntimeException;

final class SessionCredentialCipher
{
    private const CIPHER = 'aes-256-gcm';
    private const NONCE_LENGTH = 12;
    private const TAG_LENGTH = 16;

    public static function encrypt(string $value): string
    {
        $nonce = random_bytes(self::NONCE_LENGTH);
        $encrypted = openssl_encrypt($value, self::CIPHER, self::key(), OPENSSL_RAW_DATA, $nonce, $tag);
        if (!is_string($encrypted)) {
            throw new RuntimeException('Unable to encrypt database credentials.');
        }

        return base64_encode($nonce . $tag . $encrypted);
    }

    public static function decrypt(string $value): string
    {
        $payload = base64_decode($value, true);
        if ($payload === false || strlen($payload) < self::NONCE_LENGTH + self::TAG_LENGTH) {
            throw new RuntimeException('Unable to decrypt authenticated database credentials.');
        }

        $nonce = substr($payload, 0, self::NONCE_LENGTH);
        $tag = substr($payload, self::NONCE_LENGTH, self::TAG_LENGTH);
        $encrypted = substr($payload, self::NONCE_LENGTH + self::TAG_LENGTH);
        $decrypted = openssl_decrypt($encrypted, self::CIPHER, self::key(), OPENSSL_RAW_DATA, $nonce, $tag);
        if (!is_string($decrypted)) {
            throw new RuntimeException('Unable to decrypt authenticated database credentials.');
        }

        return $decrypted;
    }

    private static function key(): string
    {
        $material = getenv('SESSION_CREDENTIAL_KEY');
        if (!is_string($material) || $material === '') {
            throw new RuntimeException('Session credential encryption key is not configured.');
        }

        return hash_hkdf('sha256', $material, 32, 'decanet-session-credentials');
    }
}
