#!/usr/bin/env php
<?php

require 'NameCaseLib/Library/NCLNameCaseRu.php';
$nc = new NCLNameCaseRu();

$firstName = $argv[1] or die('Please specify a first name.');
// 1 - man, 2 - woman
$gender = $argv[2] or die('Please specify a gender.');
// 0 - nominative, 1 - genitive, 2 - dative, 3 - accusative, 4 - instrumental, 5 - prepositional
$nameCase = isset($argv[3]) ? $argv[3] : die('Please specify a case.');

echo $nc->fullReset()->setFirstName($firstName)->setGender($gender)->getFormatted($nameCase);

