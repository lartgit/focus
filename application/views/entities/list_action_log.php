<div class="row">
    <h3><?= lang($managed_class::class_plural_name()) ?></h3>
    <div class="row">

        <div class="col-md-12">

            <?php if ($url_back): ?>
                <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
                    <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                </a>
            <?php endif; ?>

        </div>
        <div class="col-md-4">
            <?php if (isset($error_string)): foreach ($errors as $error): ?>

                    <div class="error-string alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($error) ?>
                    </div>
                    <br>
                <?php endforeach;
            endif; ?>
            <div id="errors"></div>
        </div>
    </div>
    <div class="row">
        <div class="col-md-6">
            <form>
                <div class="col-md-4"> 
                    <label type="text"><?=lang('Desde')?></label>
                </div>
                <div class="col-md-4"> 
                    <label type="text"><?=lang('Hasta')?></label>
                </div>
                <div class="col-md-4">

                </div>

            </form>
        </div>
        <br/>
    </div>
    <div class="row">
        <div class="col-md-6">
            <form method="POST" action="<?= $url_filter ?>">
                <div class="col-md-3"> 
                    <input type="text"  class="form-control datet" name="dateFrom" value="<?php if (isset($date_from_to_show)) echo $date_from_to_show ?>">
                </div>
                <div class="col-md-3"> 
                    <input type="text"  class="form-control datet" name="dateTo" value="<?php if (isset($date_to_to_show)) echo $date_to_to_show ?>">
                </div>
                <div class="col-md-6">
                    <button type="submit" class="btn btn-default"><?=lang('Filtrar')?></button>   
                    &nbsp;                    
                    <a class="btn btn-default btn-md" href= "<?=$url_download?><?php if (isset($date_from_to_show)) echo "/".$date_from_to_show ?><?php if (isset($date_to_to_show)) echo "/".$date_to_to_show ?>">
                        <span class="glyphicon glyphicon-export"></span> <?= lang('Descargar') ?>
                    </a>

                </div>

            </form>
        </div>
        <br/>

    </div>
    <br/>

    <div class="row">
        <div class="col-md-8">
            <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed">
                <thead>
                    <tr class="info">
                        <th>Clase del Objeto</th>
                        <th>Objeto Id</th>
                        <th>Acción</th>
                        <th>Fecha</th>
                        <th>Usuario</th>
                    </tr>
                </thead>
                <tbody>

                    <?php foreach ($instances as $instance): ?>
                        <tr>
                            <td id="obj_class"><?= $instance->object_class ?></td>
                            <td id="obj_id">         
                                <a data-toggle="modal" data-target=".bs-example-modal-md" id="link" data-val="<?= $instance->id ?>" style="cursor:pointer" >
                                    <?= $instance->object_id ?>
                                </a>
                            </td>
                            <td><?= $instance->event ?></td>
                            <td><?= $instance->ts ?></td>
                            <td><?= $instance->user_id ?></td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>

                <tfoot>
                </tfoot>
            </table>
        </div>
    </div>
</div>
<!-- Medium Modal -->
<div class="modal fade bs-example-modal-md" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" id="modal">
    <div class="modal-dialog modal-md">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title"><?= lang('Tabla') ?></h4>
            </div>        
            <div class="modal-body" >
                <form id="form_modal" role="form" class="form-horizontal"></form>
            </div>  
        </div>
    </div>
    <!-- end Modal -->
</div>
<script>
    $(".datet").datepicker({dateFormat: "dd-mm-yy"});
    $(".datet").datepicker("option", "dayNamesMin", ["Do", "Lu", "Ma", "Mi", "Ju", "Vi", "Sa"]);
    $(".datet").datepicker("option", "monthNames", ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]);

//LLAMO A AJAX 

    $('a#link').click(function (e) {
        e.preventDefault();

//        console.log("voy a llamar a ajax");

        var ajax_read_dir = '<?= $url_show ?>';

        var row_val = $(this).attr('data-val');

        $.ajax({
            url: ajax_read_dir + row_val,
//            data: {folder: row_val},
            type: "GET",
            dataType: "html",
            beforeSend: function () {
                // $("#square").html('Cargando');
            },
            error: function (res) {
//                $("#result").html("Ocurrio un error url: " + ajax_read_dir).fadeIn("slow");
                console.log("errroorrrrrrrrr" + res);
            },
            success: function (res) {
                $("#form_modal").html('');
                //console.log(res);
                $("#form_modal").append(res).fadeIn('slow');

//                 console.log(res);
            }
        });
    });


</script>
<script>
    $(function(){
              $("#data-table").dataTable().api().order([[3,'desc']]).draw();
    })
</script>
<!-- trate de que funcionara el download xls por script, no hubo chances
<a id='file_download' style='display: none'></a>
<script>
    
function download_text_as_file(text, filename)
{
    //funcion que usa HTML5 para bajar un archivo por el navegador
    function makeTextFile(text) {
        makeTextFile.prototype.textFile = null;
        var data = new Blob([text], {type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'});

        // If we are replacing a previously generated file we need to
        // manually revoke the object URL to avoid memory leaks.
        if (makeTextFile.prototype.textFile !== null) {
            window.URL.revokeObjectURL(makeTextFile.prototype.textFile);
        }

        makeTextFile.prototype.textFile = window.URL.createObjectURL(data);

        return makeTextFile.prototype.textFile;
    };

    $('#file_download')[0].href = makeTextFile(text);
    $('#file_download')[0].download = filename;
    $('#file_download')[0].click();
}
    
$('#download_xls').click(download);

function download(e){
    e.preventDefault();

    var ajax_dt_to_xls = '<?=$url_download ?>';
    var date_from = '<?=$date_from_to_show ?>';
    var date_to = '<?=$date_to_to_show ?>';
    
         $.ajax({
         url: ajax_dt_to_xls,
         data: {d_from: date_from, d_to: date_to },
         type: "POST",
  dataType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  processData: false,
            beforeSend: function () {
               // $("#square").html('Cargando');
            },
            error: function (res) {
                download_text_as_file(res.responseText, 'logs.xlsx')

            }
         });
    // $('#modal').modal('hide');
}
</script>
    -->