/*
Copyright (c) 2003-2010, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/

CKEDITOR.editorConfig = function( config )
{
	// Define changes to default configuration here.
	// http://docs.cksource.com/ckeditor_api/symbols/CKEDITOR.config.html
	
	config.width = 800;
	config.contentsCss = '/static/css/main.css';
	
	config.toolbar_Custom = [
		['Source','-','Bold','Italic','Strike'],
		['Cut','Copy','Paste','PasteText','PasteFromWord','SpellChecker'],
		['Link','Unlink','Image'],
		['NumberedList','BulletedList','Blockquote'],
//		['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
//		['FontSize','TextColor'],
	];
	config.toolbar = 'Custom';
	
	config.menu_groups = 'clipboard,anchor,link,image';
	
	// ShinyCMS File Manager
	config.filebrowserBrowseUrl      = '/filemanager/view';
	config.filebrowserImageBrowseUrl = '/filemanager/view/images';
	config.filebrowserUploadUrl      = '/filemanager/upload';
	config.filebrowserImageUploadUrl = '/filemanager/upload/images';
	config.filebrowserWindowWidth    = '800';
	config.filebrowserWindowHeight   = '600';
};
