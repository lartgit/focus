<style>
    h5 {
        color: red;
    }
</style>
<div class="row">
    <br>
    <div class="row">
        <div class="col-md-6">
            <h3><?= lang($managed_class::class_plural_name()) ?></h3>
        </div>
        <?php if (!empty($errors)) : ?>
            <div class="col-md-6">
                <div class="alert alert-danger">
                    <strong>Errores:</strong> <?= implode("<br>", $errors) ?>
                </div>
            </div>
        <?php endif; ?>
    </div>
    <div class="row">
        <div class="col-md-12">
            <div class="panel panel-default">
                <div class="panel-heading">
                    Datos
                </div>
                <div class="panel-body">
                    <form role="form" action="<?= $url_action ?>" method="post" class="form-horizontal" enctype="multipart/form-data">
                        <input type="hidden" name="id" value="" />
                        <div class="row">
                            <div class="col-md-12">
                                <h5>Para poder crear el proceso, debe haber al menos <b>un filtro espacial</b> y <b>un filtro temporal</b> seleccionado</h5>
                            </div>
                            <div class="col-md-6">
                                <legend>Filtros espaciales</legend>
                                <div class="form-group">
                                    <label for="pixel_id" class="col-md-4 control-label">Id de Pixel</label>
                                    <div class="col-md-8">
                                        <input type="number" name="pixel_id" value="<?= $instance->pixel_id ?>" id="pixel_id" class="form-control" pattern="\d*" />
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label class="col-md-4 control-label" for="map_id">Mapa</label>
                                    <div class="col-md-8">
                                        <select class="input_form form-control multi-select2" id="map_id" name="map_id[]" multiple>
                                            <?php foreach ($maps as $entity) : ?>
                                                <option value="<?= $entity->id ?>" <?= (isset($instance->map_id) && in_array($entity->id, $instance->map_id)) ? "selected" : "" ?>><?= $entity->name ?></option>
                                            <?php endforeach; ?>
                                        </select>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label class="col-md-4 control-label" for="region_id">Region</label>
                                    <div class="col-md-8">
                                        <select class="input_form form-control multi-select2" id="region_id" name="region_id[]" multiple>
                                        </select>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label class="col-md-4 control-label" for="use_concrete_id">Uso Concreto</label>
                                    <div class="col-md-8">
                                        <select class="input_form form-control multi-select2" id="use_concrete_id" name="use_concrete_id[]" multiple>
                                            <?php $sel_uses = (isset($instance->use_concrete_id) && is_string($instance->use_concrete_id)) ? explode(",", $instance->use_concrete_id) : array(); ?>
                                            <?php foreach ($use_concretes as $entity) : ?>
                                                <option value="<?= $entity->id ?>" <?= (isset($instance->use_concrete_id) && in_array($entity->id, $sel_uses)) ? "selected" : "" ?>><?= $entity->name ?></option>
                                            <?php endforeach; ?>
                                        </select>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label class="col-md-4 control-label" for="client_id">Cliente</label>
                                    <div class="col-md-8">
                                        <select class="input_form form-control multi-select2" id="client_id" name="client_id[]" multiple>
                                            <?php $sel_clients = (isset($instance->client_id) && is_string($instance->client_id)) ? explode(",", $instance->client_id) : array(); ?>
                                            <?php foreach ($clients as $entity) : ?>
                                                <option value="<?= $entity->id ?>" <?= (isset($instance->client_id) && in_array($entity->id, $sel_clients)) ? "selected" : "" ?>><?= $entity->name ?></option>
                                            <?php endforeach; ?>
                                        </select>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label class="col-md-4 control-label" for="project_id">Projecto</label>
                                    <div class="col-md-8">
                                        <select class="input_form form-control multi-select2" id="project_id" name="project_id[]" multiple>
                                        </select>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label class="col-md-4 control-label" for="version_id">Version</label>
                                    <div class="col-md-8">
                                        <select class="input_form form-control multi-select2" id="version_id" name="version_id[]" multiple>
                                        </select>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label class="col-md-4 control-label" for="farm_id">Campo</label>
                                    <div class="col-md-8">
                                        <select class="input_form form-control multi-select2" id="farm_id" name="farm_id[]" multiple>
                                        </select>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label class="col-md-4 control-label" for="group_name">Grupo</label>
                                    <div class="col-md-8">
                                        <select class="input_form form-control multi-select2" id="group_name" name="group_name[]" multiple>
                                        </select>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label class="col-md-4 control-label" for="field_id">Lote</label>
                                    <div class="col-md-8">
                                        <select class="input_form form-control multi-select2" id="field_id" name="field_id[]" multiple>
                                        </select>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <legend>Filtros temporales</legend>
                                <h5>El filtro <b>Fecha puntual</b> y los filtros <b>Desde</b> y <b>Hasta</b> son excluyentes</h5>
                                <div class="form-group">
                                    <label for="date" class="col-md-4 control-label">Fecha puntual</label>
                                    <div class="col-md-8">
                                        <input type="text" name="date" value="<?= $instance->date ?>" id="date" class="form-control dateinput" maxlength="" />
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label for="date_from" class="col-md-4 control-label">Desde</label>
                                    <div class="col-md-8">
                                        <input type="text" name="date_from" value="<?= $instance->date_from ?>" id="date_from" class="form-control dateinput" maxlength="" />
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label for="date_to" class="col-md-4 control-label">Hasta</label>
                                    <div class="col-md-8">
                                        <input type="text" name="date_to" value="<?= $instance->date_to ?>" id="date_to" class="form-control dateinput" maxlength="" />
                                    </div>
                                </div>
                                <legend>Funciones</legend>
                                <div class="form-check">
                                    <label class="col-md-4 control-label" for="function_id">Funciones</label>
                                    <div class="col-md-8">
                                        <select class="input_form form-control multi-select2" id="function_id" name="function_id[]" multiple>
                                            <?php $sel_functions = (isset($instance->function_id) && is_string($instance->function_id)) ? explode(",", $instance->function_id) : array(); ?>
                                            <?php foreach ($functions as $entity) : ?>
                                                <option value="<?= $entity->id ?>" <?= (isset($instance->function_id) && in_array($entity->id, $sel_clients)) ? "selected" : "" ?>><?= $entity->name ?></option>
                                            <?php endforeach; ?>
                                        </select>
                                    </div>
                                </div>
                                <legend>Agrupacion</legend>
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" value="true" <?= (R2_DbObject::evaluate_variable_as_boolean($instance->group_field)) ? "checked" : "" ?> id="field" name="group_field">
                                    <label class="form-check-label" for="field">
                                        Lote
                                    </label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" value="true" <?= (R2_DbObject::evaluate_variable_as_boolean($instance->group_month)) ? "checked" : "" ?> id="month" name="group_month">
                                    <label class="form-check-label" for="month">
                                        Mes
                                    </label>
                                </div>
                                <div class="form-group" id="aggregate_function">
                                    <label class="col-md-4 control-label" for="aggregate_function">Funcion de agregación</label>
                                    <div class="col-md-8">
                                        <select class="input_form form-control" name="aggregate_function">
                                            <?php foreach (Results_two::$_aggregates as $key => $value) : ?>
                                                <option value="<?= $key ?>" <?= ($instance->aggregate_function == $key) ? "selected" : "" ?>><?= lang($key) ?></option>
                                            <?php endforeach; ?>
                                        </select>
                                        <small class="f-s-12 text-grey-darker">La funcion de agregacion aplica a todas las columnas resultantes de focus 2</small>
                                    </div>
                                </div>
                                <div class="row m-t-20 m-b-20">
                                    <div class="col-md-12">
                                        <button type="submit" class="btn btn-primary btn-sm active">Guardar</button>
                                        <button type="button" class="btn btn-danger btn-sm active" id="cancel_form">Cancelar</button>
                                    </div>
                                </div>
                                <?php /*
                                <legend>Procesos Alcanzados</legend>
                                <small class="sub-title">Esta operacion puede demorar. Por favor, no usar con filtros muy genericos.</small>
                                <div class="row">
                                    <div class="col-md-12">
                                        <button type="button" id="calculate_process" class="col-md-2 btn btn-xs btn-primary">Calcular</button>
                                        <div class="col-md-10" id="calculate_process_container">
                                            
                                        </div>
                                    </div>
                                </div>
                                */ ?>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    $(function() {
        $(".dateinput").datepicker({
            altFormat: "yy-mm-dd",
            dateFormat: "dd-mm-yy"
        });
        $(".dateinput").datepicker("option", "dayNamesMin", ["Do", "Lu", "Ma", "Mi", "Ju", "Vi", "Sa"]);
        $(".dateinput").datepicker("option", "monthNames", ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]);

        $("#cancel_form").click(function() {
            location = '<?= site_url(array("process_query_functions", "index")) ?>';
        })

        $("#calculate_process").click(function() {
            $("#calculate_process_container").html('<span class="glyphicon glyphicon-repeat fast-right-spinner"></span>');
            var formData = new FormData($("form")[0]);

            get_request("<?= site_url(array("process_query_functions", "calculate_process")) ?>", {
                method: "POST",
                body: formData
            }).then((json) => {
                $("#calculate_process_container").html(json);
            }).catch((err) => {
                $("#calculate_process_container").html(err.toString());
            });
        })


        $("#field,#month").change(function() {
            if (!$("#field").prop("checked") || $("#month").prop("checked")) {
                $("#aggregate_function").hide();
            } else {
                $("#aggregate_function").show();
            }
        }).change();

        $('.multi-select2').multiselect({
            buttonWidth: '100%',
            maxHeight: 400,
            includeSelectAllOption: true,
            selectAllText: 'Seleccionar todos',
            enableFiltering: true,
            enableCaseInsensitiveFiltering: true,
            filterPlaceholder: '<?= lang('Buscar...') ?>',
            nonSelectedText: '<?= lang('Seleccione Uno') ?>',
            nSelectedText: '<?= lang('seleccionados') ?>',
            allSelectedText: '<?= lang('Todos seleccionados') ?>',
            selectAllText: ' <?= lang('Seleccionar Todos') ?>'
        });

        var event_config = [
            ["#map_id", "regions/", "#region_id", "<?= $instance->region_id ?>"],
            ["#client_id", "projects/", "#project_id", "<?= $instance->project_id ?>"],
            ["#project_id", "versions/", "#version_id", "<?= $instance->version_id ?>"],
            ["#version_id", "farms/", "#farm_id", "<?= $instance->farm_id ?>"],
            ["#farm_id", "groups/", "#group_name", "<?= $instance->group_name ?>"],
            ["#group_name", "fields?ids=", "#field_id", "<?= $instance->field_id ?>"],
        ]

        for (const config of event_config) {
            $(config[0]).change(function() {
                var ids = "";
                if ($(this).val()) ids = $(this).val().join("_");
                get_request("<?= site_url(array("process_query_functions",)) ?>/" + config[1] + ids)
                    .then((json) => {
                        $(config[2]).html("");
                        var ids = config[3].split(",");

                        for (const opt of json) {
                            let selected = "";
                            if (ids.includes(opt.id)) selected = "selected";
                            $(config[2]).append($("<option value='" + opt.id + "' " + selected + ">" + opt.name + "</option>"));
                        }

                        $(config[2]).multiselect('rebuild');
                        $(config[2]).change();
                    })
            })
        }

        $('#map_id').change();
        $('#client_id').change();
    });

    function get_request(url, obj) {
        return fetch(url, obj)
            .then(response => {
                if (response.ok) {
                    return response.json();
                } else {
                    return response.json().then(t => {
                        throw t.Message
                    });
                }
            })
            .catch(res => {
                throw res;
            });
    }
</script>