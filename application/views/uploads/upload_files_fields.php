<div class="row">
   <h3>
      <?= lang($instance::class_plural_name()) ?> : <?=(isset($segmento_title) ? $segmento_title : '') ?>
   </h3>

   <div class="row">
      <div class="col-md-8">
         <?php if (isset($url_back)): ?>
            <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
               <span class="glyphicon glyphicon-arrow-left"></span> <?=lang('Volver')?>
            </a>
         <?php endif; ?>

      </div>
   </div>
   <br>

   <div class="row">
      <div class="col-md-8">
         <div class="panel panel-default">
            <div class="panel-heading">
                <?=lang('Datos del Formulario') ?>
            </div>
            <div class="panel-body">
               <form role="form" action="<?=$url_save_process ?>" method="post" class="form-horizontal" enctype="multipart/form-data">
                <?=$form_content ?>
                <?php if (!$upload): ?>
                <div class="form-group" data-placement="bottom" data-toggle="tooltip">
                    <label class="col-md-4 control-label">Path</label>
                    <div class="col-md-8">
                        <div class="input-group">
                            <input value="<?=(isset($instance->path) && !empty($instance->path) ? $instance->path : '')  ?>" class="form-control" type="text" id="path" name="path" readonly>
                            <?php if (!isset($show)): ?>
                                <span class="input-group-btn">
                                    <button type="button" class="btn btn-primary" data-toggle="modal" data-target=".bs-example-modal-md" id="btn-sel"><?=lang('Seleccionar')?></button>
                                </span>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>
                <?php else: ?>
                    <input type="file" name="user_file" id="user_file">
                    <div class="progress">
                        <div class="progress-bar" role="progressbar" aria-valuenow="60" aria-valuemin="0" aria-valuemax="100" style="width:80%">
                            <span class="sr-only">70% Complete</span>
                        </div>
                    </div>
                <?php endif ?>
                  <br>
                  <?php if (!isset($show)): ?>
				<input type="hidden" name="import_from" value="<?=$segmento ?>">
                     <button type="submit" id="submmit_button" class="btn btn-default ">
                        <span class="glyphicon glyphicon-save"></span> <?=lang('Grabar')?>
                     </button>
                  	<?php if ($segmento == "1"): ?>
                     <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#modal-template">
                         Formato
                     </button>
                  	<?php elseif ($segmento == "2"): ?>
                     <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#modal-template">
                         Formato
                     </button>
					<?php endif; ?>
                <?php endif; ?>
               </form>
            </div>
         </div>
      </div>
      <?php if (!isset($show)): ?>
        <div class="col-md-4">
            <div class="panel panel-info">
                <div class="panel-heading">
                    <h3 class="panel-title">Proyectos</h3>
                </div>
                <div class="panel-body">
                    <?=$Project->spit_tree($obj_tree,'tree2'); ?>
                </div>
            </div>
        <!-- end col - md -->
        </div>
        <?php endif;?>
      <div class="col-md-4" id="asdfa">
        <!-- error mesagge -->
         <?php foreach ($instance->errors() as $each): ?>
            <div class="alert alert-danger">
               <button type="button" class="close" data-dismiss="alert">&times;</button>
               <strong><?= lang('Error') ?>!</strong> <?= $each ?>
            </div>
         <?php endforeach; ?>
         <!-- success mesagge -->
        <?php if (isset($success)): foreach ($success as $message): ?>
            <div class="succes-string alert alert-success">
                <button type="button" class="close" data-dismiss="alert">&times;</button>
                <?= lang($message) ?>
            </div>
            <br />
        <?php endforeach; endif; ?>
      </div>
   </div>

<!-- Medium Modal -->
<div class="modal fade bs-example-modal-md" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" id="modal">
  <div class="modal-dialog modal-md">
    <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal">&times;</button>
          <h4 class="modal-title"><?=lang('Seleccionar Archivo')?></h4>
        </div>
        <div class="modal-body">
            <div class="panel list-group" id="list_data">
            </div>
        </div>
    </div>
  </div>
</div>

<?php if (isset($segmento) && $segmento == "1"): ?>
<div class="modal fade" tabindex="-1" role="dialog" id="modal-template">
    <div class="modal-dialog modal-md">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title"><?=lang('Template Carga')?></h4>
            </div>
            <div class="modal-body">
				<div class="row">
                    <div class="col-md-12">
                        Formato SHP de entrada:
                        <ul>
							<li>Encoding: <b>LATIN1</b>.</li>
                            <li>Debe tener, al menos, las siguientes columnas:
                                <ol>
                                    <li>'<b>depto</b>': Nombre del departamento (se usa como nombre de campo).</li>
									<li>'<b>id_lote</b>': Nombre del lote.</li>
									<li>'<b>cobertura</b>': Uso declarado.</li>
									<li>'<b>fecha</b>': Fecha de declaración. Formato: 'd/m/Y' o 'Y/m/d'.</li>
									<li>'<b>cober_con</b>': Uso concreto.</li>
									<li>'<b>fecha_desd</b>': Fecha inicio de declaración concreta. Formato: 'd/m/Y' o 'Y/m/d'.</li>
									<li>'<b>fecha_hast</b>': Fecha fin de declaración concreta. Formato: 'd/m/Y' o 'Y/m/d'.</li>
                                </ol>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<?php elseif (isset($segmento) && $segmento == "2"): ?>
<div class="modal fade" tabindex="-1" role="dialog" id="modal-template">
    <div class="modal-dialog modal-md">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title"><?=lang('Template Carga')?></h4>
            </div>
            <div class="modal-body">
				<div class="row">
                    <div class="col-md-12">
                        Formato SHP de entrada:
                        <ul>
							<li>Encoding: <b>LATIN1</b>.</li>
                            <li>Debe tener, al menos, las siguientes columnas:
                                <ol>
									<li>'<b>campo</b>': Nombre del campo.</li>
									<li>'<b>grupo</b>': Nombre del grupo del lote.</li>
									<li>'<b>lote</b>': Nombre del lote.</li>
									<li>'<b>formadesde</b>': Fecha inicio de validez del lote. Formato: 'd/m/Y' o 'Y/m/d'.</li>
									<li>'<b>formahasta</b>': Fecha fin de validez del lote. Formato: 'd/m/Y' o 'Y/m/d'.</li>
									<li>'<b>fecha</b>': Fecha de declaración. Formato: 'd/m/Y' o 'Y/m/d'.</li>
                                </ol>
                            </li>
                            <li>Y, opcionalmente, las siguientes columnas:
                                <ol>
									<li>'<b>cober</b>': Uso declarado.</li>
									<li>'<b>uso</b>': Uso concreto.</li>
									<li>'<b>uso_desde</b>': Fecha inicio de declaración concreta. Formato: 'd/m/Y' o 'Y/m/d'.</li>
									<li>'<b>uso_hasta</b>': Fecha fin de declaración concreta. Formato: 'd/m/Y' o 'Y/m/d'.</li>
                                </ol>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<?php endif; ?>
<!-- end Modal -->

<!--  -->
</div>
<script type="text/javascript">

var tag_i_fi = '<i class="fa fa-file-text"></i> ';
var tag_i_fo = '<i class="fa fa-folder"></i> ';
var current_dir = "/";


function dir_nav(e){
  e.preventDefault();


    var ajax_read_dir = '<?=$url_ajax_read_dir ?>';


        var row_val = $(this).attr('data-name');
        if (typeof(row_val) === 'undefined') {
            row_val = '';
        }

        if (this.id != 'btn-sel') {
            if (row_val == 'back') {
                new_current_dir = current_dir.split('/');
                new_current_dir.pop();
                new_current_dir.pop();
                current_dir = new_current_dir.join('/') + '/';
            }else{
                current_dir = current_dir + row_val + '/';
            }
        }

         $.ajax({
         url: ajax_read_dir,
         data: {folder: current_dir},
         type: "POST",
         dataType: "json",
            beforeSend: function () {
               // $("#square").html('Cargando');
            },
            error: function (res) {
               // $("#result").html("Ocurrio un error url: " + ajax_read_dir).fadeIn("slow");
            },
            success: function (res) {
                $('#list_data').html('');
                $('#list_data').append('<a class="list-group-item dir" href="#" data-name="back">..</a>');
                for (index = 0; index < res.length; ++index) {
                    if (res[index].type == 'dir') {
                        $('#list_data').append('<a class="list-group-item dir" href="#" data-name="'+ res[index].name +'">' + tag_i_fo + res[index].name + '</a>');
                    }else{
                        $('#list_data').append('<a class="list-group-item file" href="#" data-name="'+ res[index].name +'">' + tag_i_fi + res[index].name +'</a>');
                    }

                }
                $('a.dir').click(dir_nav);
                $('a.file').click(set_path);

            }
         });
}

$('#btn-sel').click(dir_nav);

function set_path(e){
    e.preventDefault();

    var row_val = $(this).attr('data-name');
    $('#path').val('');
    $('#path').val(current_dir+row_val);
    $('#modal').modal('hide');
}

$(function(){

    $('.ref').click(function(){
        $("select[name=project_id]").val($(this).attr('data-value')).trigger("change");

        // $('#project').val($(this).attr('data-name'));

        // $('#project_id').val($(this).attr('data-value'));
    });

});

$.fn.extend({
    treed: function (o) {

      var openedClass = 'glyphicon-minus-sign';
      var closedClass = 'glyphicon-plus-sign';

      if (typeof o != 'undefined'){
        if (typeof o.openedClass != 'undefined'){
        openedClass = o.openedClass;
        }
        if (typeof o.closedClass != 'undefined'){
        closedClass = o.closedClass;
        }
      };

        //initialize each of the top levels
        var tree = $(this);
        tree.addClass("tree");
        tree.find('li').has("ul").each(function () {
            var branch = $(this); //li with children ul
            branch.prepend("<i class='indicator glyphicon " + closedClass + "'></i>");
            branch.addClass('branch');
            branch.on('click', function (e) {
                if (this == e.target) {
                    var icon = $(this).children('i:first');
                    icon.toggleClass(openedClass + " " + closedClass);
                    $(this).children().children().toggle();
                }
            })
            branch.children().children().toggle();
        });
        //fire event from the dynamically added icon
      tree.find('.branch .indicator').each(function(){
        $(this).on('click', function () {
            $(this).closest('li').click();
        });
      });
        //fire event to open branch if the li contains an anchor instead of text
        tree.find('.branch>a').each(function () {
            $(this).on('click', function (e) {
                $(this).closest('li').click();
                e.preventDefault();
            });
        });
        //fire event to open branch if the li contains a button instead of text
        tree.find('.branch>button').each(function () {
            $(this).on('click', function (e) {
                $(this).closest('li').click();
                e.preventDefault();
            });
        });
    }
});

//Initialization of treeviews

$('#tree2').treed();

    $("[name=client_id]").change(function (e) {
        e.preventDefault();

        var project_id = '<?=$instance->project_id?>';

        var row_val = $(this).val();

        if (row_val != '') {
            var ajax_project_client = '<?= $url_ajax_project_client ?>';

            $.ajax({
                url: ajax_project_client,
                type: "POST",
                data: {client: row_val},
                dataType: "json",
                beforeSend: function () {
                    // $("#square").html('Cargando');
                },
                error: function (res) {
                    // console.log("errroorrrrrrrrr" + res);
                },
                success: function (res) {
                    // console.log(res[0].client_id);
                    $('[name=project_id]')[0].innerHTML = '';
                    $.each(res, function(_, a) {
                        var opt = $('<option>').attr('value', a.id).append(a.name);
                        if(a.id == project_id) opt.attr('selected', 'selected');
                        $('[name=project_id]').append(opt);
                    });
                    $("[name=project_id]").change();
                }
            });
        }
    }).change();

    $("[name=project_id]").change(function (e) {
        e.preventDefault();

        var ajax_version_by_project = '<?= $url_ajax_version_project ?>';

        var  version_id = '<?=$instance->version_id ?>';

        var row_val = $(this).val();

        var version = $("select[name=version_id]");

        $.ajax({
            url: ajax_version_by_project + row_val,
            type: "GET",
            dataType: "json",
            beforeSend: function () {
                // $("#square").html('Cargando');
            },
            error: function (res) {
                // console.log("errroorrrrrrrrr" + res);
            },
            success: function (res) {
                // Limpiamos el select
                version.html("");
                // console.log(res);
                //cargo combo use_concret
                for (var i = 0; i < res.length; i++) {
                    combo = $('<option>').text(res[i].name).attr('value', res[i].id);
                    if (res[i].id == version_id) combo.attr('selected', 'selected');
                    version.append(combo);
                }
            }
        });
    }).change();
</script>
<script>
$(document).ready(function(){
    $('#path').tooltip({title: "<?=lang('Seleccione el Shape File (.shp) con los lotes a procesar')?>"});
});
</script>
