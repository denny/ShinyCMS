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
	// Set same font/bg/etc inside editor as on front-end site
	config.contentsCss = '/static/css/main.css';

	// The toolbar groups arrangement, optimized for two toolbar rows.
	config.toolbarGroups = [
		{ name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
		{ name: 'clipboard',   groups: [ 'clipboard', 'undo' ] },
		{ name: 'links'  },
		{ name: 'insert' },
		{ name: 'paragraph',   groups: [ 'list', 'indent', 'blocks', 'align', 'bidi' ] },
		{ name: 'editing',     groups: [ 'find', 'selection', 'spellchecker' ] },
		{ name: 'document',    groups: [ 'mode', 'document', 'doctools' ] },
		{ name: 'tools'  },
//		'/',
//		{ name: 'others' },
//		{ name: 'styles' },
//		{ name: 'colors' },
//		{ name: 'about'  }
	];

	// Remove some buttons provided by the standard plugins, 
	// which are not needed in the Standard(s) toolbar.
	config.removeButtons = 'Underline,Subscript,Superscript,RemoveFormat,SpecialChar,PasteFromWord';

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
