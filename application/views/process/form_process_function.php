<script type="text/javascript" src="<?= base_url() ?>/assets/js/moment.min.js"></script>
<div class="row">
    <h3>
        <?= lang($instance::class_plural_name()) ?>
    </h3>

    <div class="row">
        <div class="col-md-8">
            <?php if (isset($url_back)) : ?>
                <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
                    <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                </a>
            <?php endif; ?>
        </div>
    </div>
    <br>

    <div class="row">
        <div class="col-md-7">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <?= lang('Datos') ?>
                </div>
                <div class="panel-body">
                    <form role="form" action="<?= $url_action ?>" method="post" class="form-horizontal" enctype="multipart/form-data">
                        <input id="process_result_id" name="process_result_id" type="hidden" />
                        <?= $form_content ?>
                        <!-- Función -->
                        <input id="function_id" name="function_id" type="hidden" />
                        <div class="form-group">
                            <label class="col-md-4 control-label"><?= lang('Función') ?></label>
                            <div class="col-md-5">
                                <input class="input_form form-control" id="function_name_to_show" type="text" disabled />
                            </div>
                            <div class="search-request col-md-3">
                                <!-- Trigger the modal with a button -->
                                <button id="startclick" type="button" class="btn btn-info col-md-12" data-toggle="modal" data-target="#modal_function" <?php if (isset($show)) echo 'disabled' ?>>
                                    <?= lang('Buscar Funcion') ?> </button>
                            </div>
                        </div>
                        <!-- Focus 1 -->
                        <div class="form-group">
                            <label class="col-md-4 control-label"><?= lang('Focus 1') ?></label>
                            <div class="col-md-5">
                                <input class="input_form form-control" id="result_name_to_show" type="text" disabled />
                            </div>
                            <div class="search-request col-md-3">
                                <!-- Trigger the modal with a button -->
                                <button id="startclick" type="button" class="btn btn-info col-md-12" data-toggle="modal" data-target="#modal_result" <?php if (isset($show)) echo 'disabled' ?>>
                                    <?= lang('Buscar Proceso Focus 1') ?> </button>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label"><?= lang('Mapa de Regiones') ?></label>
                            <div class="col-md-8">
                                <select class="input_form form-control" id="map_id" name="map_id" required>
                                    <option></option>
                                    <?php foreach ($maps as $map) : ?>
                                        <option value="<?= $map->primary_key_value() ?>" <?= ($instance->map_id == $map->primary_key_value()) ? 'selected' : '' ?>><?= $map->display_value() ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label"><?= lang('Dates') ?></label>
                            <div class="col-md-3">
                                <button id="btn-add-date" type="button" class="col-md-12 btn btn-primary" <?php if (isset($show)) echo 'disabled' ?>><?= lang('add_date') ?></button>
                            </div>
                            <div class="col-md-3">
                                <button id="btn-add-date" type="button" class="col-md-12 btn btn-primary" data-toggle="modal" data-target="#modal_dates" <?php if (isset($show)) echo 'disabled' ?>><?= lang('image_date_modal') ?></button>
                            </div>
                        </div>
                        <div class="form-group">
                            <label for="" class="col-md-4 control-label"></label>
                            <div class="col-md-8" id="input_fields_wrap">
                            </div>
                        </div>
                        <?php if (!isset($show)) : ?>
                            <button type="submit" id="submmit_button" class="btn btn-default ">
                                <span class="glyphicon glyphicon-save"></span> <?= lang('Grabar') ?>
                            </button>
                        <?php endif; ?>
                    </form>
                </div>
            </div>
        </div>
        <div class="col-md-5" id="asdfa">
            <!-- error mesagge -->
            <?php foreach ($instance->errors() as $each) : ?>
                <div class="alert alert-danger">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <strong><?= lang('Error') ?>!</strong> <?= $each ?>
                </div>
            <?php endforeach; ?>
            <!-- success mesagge -->
            <?php if (isset($success)) : foreach ($success as $message) : ?>
                    <div class="succes-string alert alert-success">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= $message ?>
                    </div>
                    <br />
            <?php
                endforeach;
            endif; ?>
        </div>
    </div>

    <!-- Modal Function -->
    <div class="modal fade" role="dialog" id="modal_function">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                    <h4 class="modal-title"><?= lang('Buscar Funcion') ?></h4>
                </div>
                <div class="modal-body">
                    <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed searching-table">
                        <thead>
                            <tr class="info">
                                <th><?= lang('Nombre') ?></th>
                                <th><?= lang('Usuario') ?></th>
                                <th><?= lang('Fecha') ?></th>
                                <th><?= lang('Archivo') ?></th>
                                <th><?= lang('Seleccionar') ?></th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (isset($functions)) : ?>
                                <?php foreach ($functions as $row) : ?>
                                    <tr class="clickable-row" data-dismiss="modal" onclick="select_function({<?= "'id':'$row->id', 'name':'$row->name'" ?>})">
                                        <td style="padding-left: 20px;
                                            text-align: center;">
                                            <?= $row->name ?>
                                        </td>
                                        <td style="padding-left: 20px;
                                            text-align: center;">
                                            <?= $row->user ?>
                                        </td>

                                        <td style="padding-left: 20px;
                                            text-align: center;">
                                            <?= $row->ts ?>
                                        </td>

                                        <td style="padding-left: 20px;
                                            text-align: center;">
                                            <?= $row->path_name() ?>
                                        </td>
                                        <td><a style="cursor: pointer; color:blue;" onclick="select_function({<?= "'id':'$row->id', 'name':'$row->name'" ?>})"><?= lang('Seleccionar') ?></a></td>
                                    </tr>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal"><?= lang('close') ?></button>
                </div>
            </div>
        </div>
    </div>
    <!-- Procesos Focus 1  -->
    <div class="modal fade" role="dialog" id="modal_result">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                    <h4 class="modal-title"><?= lang('Buscar Proceso Focus 1') ?></h4>
                </div>
                <div class="modal-body">
                    <table class="data-table table table-striped table-bordered table-hover table-responsive table-condensed searching-table">
                        <thead>
                            <tr class="info">
                                <th><?= lang('Nombre') ?></th>
                                <th><?= lang('Escenas') ?></th>
                                <th><?= lang('Client/Proyecto/Version') ?></th>
                                <th><?= lang('Regla de Selección de Pixeles') ?></th>
                                <th><?= lang('Seleccionar') ?></th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if (isset($process_results)) : ?>
                                <?php foreach ($process_results as $process) : ?>
                                    <tr class="clickable-row" data-dismiss="modal" onclick="select_result({<?= "'id':'$process->id', 'name':'$process->name'" ?>})">
                                        <td> <a href="<?= $url_show_process_focus_1 ?><?= $process->id ?>"> <?= $process->name ?> </a></td>
                                        <td><?= $process->pixel_set_name ?></td>
                                        <td title="<?= $process->cli_name . '/' . $process->proy_name . '/' . $process->version_name ?>"><?= $process->cli_name . '/' . $process->proy_name . '/' . $process->version_name ?></td>
                                        <td><?= $process->px_rule_name ?></td>
                                        <td><a style="cursor: pointer; color:blue;" onclick="select_result({<?= "'id':'$process->id', 'name':'$process->name'" ?>})"><?= lang('Seleccionar') ?></a></td>
                                    </tr>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal"><?= lang('close') ?></button>
                </div>
            </div>
        </div>
    </div>
    <!-- Modal Fechas Imagenes -->
    <div class="modal fade" role="dialog" id="modal_dates">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                    <h4 class="modal-title"><?= lang('Buscar Funcion') ?></h4>
                </div>
                <div class="modal-body">
                    <div class="form-horizontal">
                        <div class="form-group">
                            <label class="col-md-4 control-label"><?= lang('Tipo de Imagen') ?></label>
                            <div class="col-md-8">
                                <select class="form-control" id="image_types">
                                    <?php foreach ($image_types as $value) : ?>
                                        <option value="<?= $value->primary_key_value() ?>"><?= $value->display_value() ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label"><?= lang('Fecha Desde') ?></label>
                            <div class="col-md-8">
                                <input name="date_from" value="" id="date_from" class="form-control datepicker" maxlength="50" type="text">
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label"><?= lang('Fecha Hasta') ?></label>
                            <div class="col-md-8">
                                <input name="date_to" value="" id="date_to" class="form-control datepicker" maxlength="50" type="text">
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label"></label>
                            <div class="col-md-8">
                                <button id="update_image_dates" class="col-md-3 btn btn-primary"><?= lang('Update') ?></button>
                            </div>
                        </div>
                    </div>
                    <div id="table_loc"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-primary" data-dismiss="modal" id="add_all_dates"><?= lang('Add All Dates') ?></button>
                    <button type="button" class="btn btn-default" data-dismiss="modal"><?= lang('close') ?></button>
                </div>
            </div>
        </div>
    </div>

</div>

<script>
    var get_image_dates_url = '<?= $get_image_dates_url ?>';

    var arrdata = [];

    function select_function(obj) {
        $('#function_id')[0].value = obj.id;
        $('#function_name_to_show')[0].value = obj.name;
        // dialog.dialog("close");
    };

    function select_result(obj) {
        $('#process_result_id')[0].value = obj.id;
        $('#result_name_to_show')[0].value = obj.name;
        // dialog.dialog("close");
    };

    function redraw_table() {
        createTable('table_loc',
            ['<?= lang('Name') ?>', '<?= lang('CP') ?>', '<?= lang('Used in Group') ?>', '<?= lang('Agregar') ?>'],
            arrdata, [null, null, null, add_date], {
                no_data_title: "<?= lang('Sin Localidades') ?>"
            }
        );
    }

    function InputDates(wrapper) {
        this.dates = [];
        this.wrapper = wrapper;
        var that = this;

        this.is_in_array = function(arg_date) {
            for (var i = 0; i < this.dates.length; i++) {
                if (this.dates[i] == arg_date) return true;
            }
            return false;
        }

        this.add_date = function(init_value) {
            if (init_value) {
                if (!this.is_in_array(init_value)) {
                    this.dates.push(init_value);
                }
            } else {
                this.dates.push('');
            }
            return this;
        }

        this.update_date = function(e) {
            that.dates[$(this).data('idx')] = $(this).val();
        }

        this.remove_date = function(idx) {
            this.dates.splice(idx, 1);
            return this;
        }

        this.redraw = function() {
            var data = '';

            remove_link = this.dates.length == 1 ? '' : '<a href="#" class="remove_field">Remove</a>';
            for (var i = 0; i < this.dates.length; i++) {
                data += '<div data-idx="' + i + '" id="date_container_' + i + '">' +
                    '    <input data-idx="' + i + '" class="form-control date_input" type="text" name="date_column[]" id="date_input_' + i + '" value="' + this.dates[i] + '" />' + remove_link +
                    '</div>'; //add input
            }

            wrapper.html(data);

            init_datepicker(".date_input");
            $('.date_input').keypress(this.update_date).change(this.update_date);

            var that = this;
            $(".remove_field").click(function(e) { //remove input
                e.preventDefault();
                that.remove_date($(this).parent().data('idx')).redraw();
            })

            return this;
        }

        return this;
    }

    var inputDates = InputDates($("#input_fields_wrap"));

    function init_datepicker(selector) {
        $(selector).datepicker({
            dateFormat: "dd-mm-yy"
        });
        $(selector).datepicker("option", "dayNamesMin", ["Do", "Lu", "Ma", "Mi", "Ju", "Vi", "Sa"]);
        $(selector).datepicker("option", "monthNames", ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]);
    }


    $(function() {
        // redraw_table();
        init_datepicker("#date_column,#date_from,#date_to");

        //***************************************************
        // La funcionalidad de agregar y remover inputs
        //***************************************************
        //cantidad de columnas mas de 10???

        init_dates = <?= isset($column_dates) ? json_encode($column_dates) : "['']" ?>;

        for (var i = 0; i < init_dates.length; i++) {
            inputDates.add_date(init_dates[i]);
        }
        inputDates.redraw();

        /*
            <?php if (!isset($column_dates)) : ?>
                <input name="date_column[]" value="" id="date_column" class="form-control datepicker" maxlength="50" type="text">
            <?php else : ?>
                <?php $i = 0;
                foreach ($column_dates as $each) : ?>
                    <div>
                        <input name="date_column[]" value="<?= $each ?>" id="date_column" class="form-control datepicker" maxlength="50" type="text">
                        <?php if ($i != 0) : ?>
                            <a href="#" class="remove_field">Remove</a>
                        <?php endif; ?>
                    </div>
                <?php $i++;
                endforeach; ?>
            <?php endif; ?>
        */

        var add_button = $("#btn-add-date");
        $(add_button).click(function(e) {
            e.preventDefault();
            inputDates.add_date().redraw();
        });


        //***************************************************
        //End Add or remove inputs
        //***************************************************

        $('#update_image_dates').click(update_image_dates);
        $('#add_all_dates').click(add_all_dates);
    });

    dates_cache = [];

    function update_image_dates(e) {
        e.preventDefault();

        date_from = moment($('#date_from').val(), 'DD-MM-YYYY');
        if (!date_from.isValid()) date_from = "";
        else date_from = date_from.format('YYYY-MM-DD')

        date_to = moment($('#date_to').val(), 'DD-MM-YYYY');
        if (!date_to.isValid()) date_to = "";
        else date_to = date_to.format('YYYY-MM-DD');

        $.get(get_image_dates_url, {
            image_type_id: $('#image_types').val(),
            date_from: date_from,
            date_to: date_to
        }, function(res) {

            dates_cache = [];
            dates_data = [];
            for (i = 0; i < res.length; i++) {
                var date = moment(res[i]).format('DD-MM-YYYY');
                dates_cache.push(date);
                dates_data.push({
                    id: date,
                    data: [date]
                });
            }

            createTable('table_loc', ['<?= lang('Fecha') ?>'], dates_data, [], {
                no_data_title: "<?= lang('Sin Fechas') ?>",
                pagination: false,
                search: false
            });

        }, 'json');
    }

    function add_all_dates(e) {
        e.preventDefault();

        for (var i = 0; i < dates_cache.length; i++) {
            inputDates.add_date(dates_cache[i]);
        }
        inputDates.redraw();
    }
</script>