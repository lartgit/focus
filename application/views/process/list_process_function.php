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
    $(function () {
        $('.sel-filter').multiselect().change(function (e) {
            e.preventDefault();
            var ajax_read_dir = '<?= $url_ajax_datatables ?>';
            var user_val = $('#user_filter').val();
            var fun_val = $('#function_filter').val();
            var proc_val = $('#process_filter').val();
            var status_val = $('#status_filter').val();

            $.ajax({
                url: ajax_read_dir,
                data: {user_filter: user_val, function_filter: fun_val, process_filter: proc_val, status_filter: status_val},
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
        });

        //para que se corra por primera vez
        $('#user_filter').change();
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
</style>

<div class="row">
    <br>
    <div class="row">
        <div class="col-md-6"> <h3><?= lang($managed_class::class_plural_name()) ?></h3> </div>
        <div class="col-md-6">
            <div class="alert alert-info">
                <strong>Info:</strong> <?= lang('descripcion_de_pantalla_procesos_para_importacion') ?> 
            </div>
        </div>
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
            <a class="btn btn-default btn-sm" href="<?= $url_report ?>">
                <span class="glyphicon glyphicon-plus"></span> <?= lang('Reporte de Procesos') ?>
            </a>
        </div>

        <div class="col-md-4">
            <?php if (isset($error_string)): foreach ($errors as $error): ?>
                    <div class="error-string alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= $error ?>
                    </div>
                    <?php
                endforeach;
            endif;
            ?>
            <div id="errors"></div>

            <?php if (isset($success)): foreach ($success as $message): ?>
                    <div class="succes-string alert alert-success">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= $message ?>
                    </div>
                    <br />
                    <?php
                endforeach;
            endif;
            ?>
        </div>
        <!-- End row -->
    </div>
    <br>
    <label class="control-label"><?= lang('Filtros') ?> </label>
    <div class="alert alert-info">

        <div class="row">
            <div class="col-md-3">
                <label for="user_filter"><?= lang('Usuarios') ?></label>
                <br>
                <!-- lo ideal aca sería usar select picker y delimitar la cantidad de elecciones 
                <select class="selectpicker" multiple data-selected-text-format="count > 3">
                -->

                <select value="" class="sel-filter form-control" type="" id="user_filter" name="user_filter" multiple="multiple">
                    <?php foreach ($filters['users'] as $each): ?>
                        <option value="<?= $each->id ?>" ><?= $each->name ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-3">
                <label for="function_filter"><?= lang('Funciones') ?></label>
                <br>
                <select value="" class="sel-filter form-control" type="" id="function_filter" name="function_filter" multiple="multiple">
                    <?php foreach ($filters['functions'] as $each): ?>
                        <option value="<?= $each->id ?>" ><?= $each->name ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-3">
                <label for="process_filter"><?= lang('Proceso Focus 1') ?></label>
                <br>
                <select value="" class="sel-filter form-control" type="" id="process_filter" name="process_filter" multiple="multiple">
                    <?php foreach ($filters['process_results'] as $each): ?>
                        <option value="<?= $each->id ?>" ><?= $each->name ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-3">
                <label for="status_filter"><?= lang('Estatus') ?></label>
                <br>
                <select value="" class="sel-filter form-control" type="" id="status_filter" name="status_filter" multiple="multiple">
                    <?php foreach ($filters['statuses'] as $each): ?>
                        <option value="<?= $each ?>" ><?= lang($each) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
        </div>
    </div>
    <br>
    <div class="row">
        <div class="col-md-12" id="data-table_div">
        </div>
    </div>
</div>
