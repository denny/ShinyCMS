/**
 * @license Copyright (c) 2003-2014, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.md or http://ckeditor.com/license
 */

CKEDITOR.editorConfig = function( config ) {
	// Define changes to default configuration here.
	// For complete reference see:
	// http://docs.ckeditor.com/#!/api/CKEDITOR.config

	// Set 800px wide instead of full page width
	config.width = 800;

	// Toolbar
	config.toolbarGroups = [
		{ name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
		{ name: 'clipboard',   groups: [ 'clipboard', 'undo' ] },
		{ name: 'links'  },
		{ name: 'insert' },
		{ name: 'paragraph',   groups: [ 'list', 'indent', 'blocks' ] },
		{ name: 'editing',     groups: [ 'find', 'selection', 'spellchecker' ] },
		{ name: 'document',    groups: [ 'mode', 'document', 'doctools' ] },
		{ name: 'tools'  }
	];

	// Remove a load of buttons which we don't want by default
	config.removeButtons = 'Underline,Subscript,Superscript,RemoveFormat,'
		+ 'PasteFromWord,'
		+ 'Flash,Table,Smiley,SpecialChar,PageBreak,Iframe,'
		+ 'CreateDiv,'
		+ 'Find,Replace,SelectAll,'
		+ 'Save,NewPage,Preview,Print,Templates,'
		+ 'ShowBlocks';

	// Simplify the dialog windows.
	config.removeDialogTabs = 'image:advanced;link:advanced';
	
	// Add hooks for ShinyCMS File Manager
	config.filebrowserBrowseUrl      = '/admin/filemanager/view';
	config.filebrowserImageBrowseUrl = '/admin/filemanager/view/images';
	config.filebrowserUploadUrl      = '/admin/filemanager/upload';
	config.filebrowserImageUploadUrl = '/admin/filemanager/upload/images';
	config.filebrowserWindowWidth    = '800';
	config.filebrowserWindowHeight   = '600';
};

