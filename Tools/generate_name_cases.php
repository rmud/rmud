#!/usr/bin/env php
<?php

require 'NameCaseLib/Library/NCLNameCaseRu.php';
$nc = new NCLNameCaseRu();

$firstName = $argv[1] or die('Please specify a first name.');
// 1 - man, 2 - woman
$gender = $argv[2] or die('Please specify a gender.');

$nc->fullReset()->setFirstName($firstName)->setGender($gender);

echo $nc->getFormatted(1, 'N') . ' ' .
    $nc->getFormatted(2, 'N') . ' ' .
    $nc->getFormatted(3, 'N') . ' ' .
    $nc->getFormatted(4, 'N') . ' ' .
    $nc->getFormatted(5, 'N');

