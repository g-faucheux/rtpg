/*

AUTHORS

 Copyright (C) 2010 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2010 Nikolaev Roman <rshadow@rambler.ru>

LICENSE

This program is free software: you can redistribute  it  and/or  modify  it
under the terms of the GNU General Public License as published by the  Free
Software Foundation, either version 3 of the License, or (at  your  option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even  the  implied  warranty  of  MERCHANTABILITY  or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public  License  for
more details.

You should have received a copy of the GNU  General  Public  License  along
with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

/*
    This file contain java scripts for List frame
*/

$(document).ready(function(){
    // Restore frames positions
//    $('#frms_middle').attr('cols', $.cookie('frms_middle'));
//    $('#frms_content').attr('rows', $.cookie('frms_content'));

    // Save frame position on resize
    $('#frms_main').bind('resize', function(){ alert( $(this).id() )} );
    $('#frms_middle').bind('resize', function(){ alert( $(this).id() )} );
    $('#frms_content').bind('resize', function(){ alert( $(this).id() )} );

//alert( window.frames(3).bind('resize', function(){ alert( $(this).id() )} ); );
//    $(window.parent.frames[2]).bind(
//        'resize',
//        function(){
//            $(document).ready(function(){
//                alert( $(window.parent.frames[2]).parent().attr('row') );
//            });
//        });
});

//function on_resize()
//{
//    alert( $(this).id() );
//    $.each($('frameset'), function( i, objFrameset ){
//        $.cookie(objFrameset.id(), objFrameset.attr('rows'));
//    });
//}