<script>
    function init_dt() {
        $("#data-table-xls5").DataTable({
            dom: 'Bfrtip',
            buttons: [
                {
                    extend: 'excelHtml5',
                    text: 'Excel',
                    exportOptions: {
                        columns: [1, 2, 3, 4, 5]

                    }
                },
                {
                    extend: 'csvHtml5',
                    text: 'CSV',
                    exportOptions: {
                        columns: [1, 2, 3, 4, 5]
                    }
                }
            ],
            "order": [[ 1, 'asc' ], [ 0, 'desc' ]]
        });

        $("#data-table-xls6").DataTable({
            dom: 'Bfrtip',
            buttons: [
                {
                    extend: 'excelHtml5',
                    text: 'Excel',
                    exportOptions: {
                        columns: [0, 1, 2, 3, 4]

                    }
                },
                {
                    extend: 'csvHtml5',
                    text: 'CSV',
                    exportOptions: {
                        columns: [0, 1, 2, 3, 4]
                    }
                }
            ],
            "order": [[ 0, 'asc' ], [ 1, 'desc' ]]
        });
    }
</script>
<script type="text/javascript">
    //cuando cambia el cliente traigo los projects
    var ajax_read_dir = '<?= $url_ajax_datatables ?>';

    $.ajax({
        url: ajax_read_dir,
        type: "POST",
        beforeSend: function () {

        },
        error: function (res) {

        },
        success: function (res) {
            $('#data-table_div').empty();
            $('#data-table_div').html(res);
            init_dt();
        }
    });
</script>
<style>
    .multiselect .dropdown-toggle .btn .btn-default  {
        position: relative;
        z-index: 2;
        float: left;
        width: 100%;
        margin-bottom: 0;
        display: table;
        table-layout: fixed;
    }
    #data-table-xls6_wrapper {
        overflow: auto;
        width: 100%;
    }
</style>

<div class="row">
    <div class="col-md-6"> <h3><?= lang($managed_class::class_plural_name()) ?></h3> </div>
<!--    <div class="col-md-6">
        <div class="alert alert-info">
            <strong>Info:</strong> <?= lang('descripcion_de_pantalla_procesos_para_importacion') ?>
        </div>
    </div>-->
</div>
<div class="row">

    <div class="col-md-6">
        <br>
        <?php if ($url_back): ?>
            <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
                <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
            </a>
        <?php endif; ?>
        &nbsp;
        <?php if ($user_can_add): ?>
            <a class="btn btn-default btn-sm" href="<?= $url_new ?>">
                <span class="glyphicon glyphicon-plus"></span> <?= lang('Nuevo Proceso') ?>
            </a>
        <?php endif; ?>
        <!-- <a class="btn btn-default btn-sm" href="<?= $url_report ?>">
            <span class="glyphicon glyphicon-plus"></span> <?= lang('Reporte de Procesos') ?>
        </a> -->
    </div>

    <div class="col-md-4">
        <?php if (isset($error_string)): foreach ($errors as $error): ?>
            <div class="error-string alert alert-danger">
                <button type="button" class="close" data-dismiss="alert">&times;</button>
                <?= $error ?>
            </div>
        <?php endforeach; endif; ?>
        <div id="errors"></div>

        <?php if (isset($success)): foreach ($success as $message): ?>
            <div class="succes-string alert alert-success">
                <button type="button" class="close" data-dismiss="alert">&times;</button>
                <?= $message ?>
            </div>
            <br />
        <?php endforeach; endif; ?>
    </div>
    <!-- End row -->
</div>
<br>
<div class="row">
    <div class="col-md-12" id="data-table_div">
    </div>
</div>
