#!/bin/sh
set -e

if [ "$1" = 'apache2-foreground' ] || [ "$1" = 'php' ]; then
  php vendor/bin/typo3cms install:fixfolderstructure --no-ansi
  php vendor/bin/typo3cms language:update --no-ansi
  php vendor/bin/typo3cms cache:flush
fi

exec docker-php-entrypoint "$@"
