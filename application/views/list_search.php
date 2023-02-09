<div class="row">
    <h3><?= lang('Resultado de la busqueda') ?></h3>
    <div class="row">

        <div class="col-md-4">
            <?php if (isset($error_string)): foreach ($errors as $error): ?>

                    <div class="error-string alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($error) ?>
                    </div>
                    <br>
                    <?php
                endforeach;
            endif;
            ?>
            <div id="errors"></div>
        </div>
    </div>
    <div class="row">
        <div class="col-md-8">
            <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed">
                <thead>
                    <tr class="info">
                        <th>Nombre</th>
                        <th>Clase del Objeto</th>
                        <th>Fecha de modificación</th>
                    </tr>
                </thead>
                <tbody>

                    <?php foreach ($instances as $instance): ?>
                        <tr>
                            <?php $aux_class = $instance->class_name ?>
                            <td> <a data-toggle="modal" data-target=".bs-example-modal-md" id="link" data-val="<?= $instance->id . "_" . $instance->class_name ?>" style="cursor:pointer" >
                                    <?= $instance->display ?>
                                </a>
                            </td>
                            <td id="class_name"><?= $aux_class::class_display_name() ?></td>

                            <td><?= $instance->ts ?></td>
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

        var ajax_read_dir = '<?= $url_show ?>';

        var row_val = $(this).attr('data-val');

        $.ajax({
            url: ajax_read_dir + row_val,
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
                $("#form_modal").append(res).fadeIn('slow');
            }
        });
    });


</script>
<script>
    $(function () {
        $("#data-table").dataTable().api().order([[2, 'desc']]).draw();
    })
</script>