<?php
$Vtiger_Utils_Log = true;

include_once 'vtlib/Vtiger/Module.php';
$myExtensionModule = Vtiger_Module::getInstance('TicketMap');
if ($myExtensionModule) {
	Vtiger_Utils::Log("Module already exits.");
} else {
	$myExtensionModule = new Vtiger_Module();
	$myExtensionModule->name = 'TicketMap';
	$myExtensionModule->label= 'Ticket Map';
	$myExtensionModule->parent='Tools';
	$myExtensionModule->save();
}