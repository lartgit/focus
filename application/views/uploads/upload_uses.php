<div class="row">
   <h3>
      <?= lang($instance::class_plural_name()) ?>
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
                <?=lang('Datos de asignacion de usos') ?>
            </div>
            <div class="panel-body">
               <form role="form" action="<?=$url_save_process ?>" method="post" class="form-horizontal" enctype="multipart/form-data" >
                <?=$form_content ?>
                <?php if (!$upload1): ?>
                <div class="form-group" data-placement="bottom" data-toggle="tooltip">
                    <label class="col-md-4 control-label">Archivo</label>
                    <div class="col-md-8">
                        <input type="file"  id="user_file" name="user_file">
                    </div>
                </div>
                <?php else: ?>
                    <input type="file" name="user_file" id="user_file">
                    <div class="progress">
                        <div class="progress-bar" role="progressbar" aria-valuenow="60" aria-valuemin="0" aria-valuemax="100" style="width:80%">
                            <span class="sr-only"> 70% Complete </span>
                        </div>
                    </div> 
                <?php endif ?>
                  <br>
                  <?php if (!isset($show)): ?>
                     <button type="submit" id="submmit_button" class="btn btn-default ">
                        <span class="glyphicon glyphicon-save"></span> <?=lang('Grabar')?>
                     </button>
                     <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#modal-template">
                         Formato <strong>Usos</strong>
                     </button>
                  <?php endif; ?>
               </form>
            </div>
         </div>
      </div>      
        <div class="col-md-4">
            <?php if (isset($errors)): foreach ($errors as $error): ?>
                <div class="error-string alert alert-danger">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <?= $error ?>
                </div>
            <?php endforeach; endif; ?>
            <div id="errors"></div>
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
                        Formato CSV o Excel de entrada:
                        <ul>
							<li>En caso de CSV. Campos separado por ';' (punto y coma).</li>
							<li>Con cabecera.</li>
                            <li>Debe tener, al menos, las siguientes columnas:
                                <ol>
                                    <li>'<b>GRUPO</b>': Nombre del grupo del lote.</li>
									<li>'<b>CAMPO</b>': Nombre del campo que contiene el lote.</li>
									<li>'<b>LOTE</b>': Nombre del lote.</li>
									<li>'<b>FECHA</b>': Fecha de declaración. Formato: 'd/m/Y'.</li>
									<li>'<b>USODESDE</b>': Fecha inicio de declaración concreta. Formato: 'd/m/Y'.</li>
									<li>'<b>USOHASTA</b>': Fecha fin de declaración concreta. Formato: 'd/m/Y'.</li>
									<li>'<b>USO</b>': Nombre de uso concreto.</li>
                                </ol>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
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