#!/usr/bin/env php
<?php

require 'NameCaseLib/Library/NCLNameCaseRu.php';
$nc = new NCLNameCaseRu();

$firstName = $argv[1] or die('Please specify a person\'s name.');

$gender = $nc->fullReset()->setFirstName($firstName)->genderAutoDetect();

// 1 - man, 2 - woman
echo $gender;

