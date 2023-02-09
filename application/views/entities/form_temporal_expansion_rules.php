<div class="row">
    <h3>
        <?= lang($managed_class::class_plural_name()) ?>
        <?= ($instance->display_value()) ? ' > ' . $instance->display_value() : '' ?>
    </h3>

    <div class="row">
        <div class="col-md-8">
            <?php if (isset($url_back)): ?>
                <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
                    <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                </a>
            <?php endif; ?>

        </div>
        <div class="col-md-4">

        </div>
    </div>
    <br>

    <div class="row">
        <div class="col-md-8">
            <div class="panel panel-default">
                <div class="panel-body">
                    <form role="form" action="<?= $url_action ?>" method="post" class="form-horizontal">
                        <input type="hidden" value="<?= $instance->id ?>" name="id">
                        <div class="form-group">
                            <label class="col-md-4 control-label">Region</label>
                            <div class="col-md-8">

                                <select value="" class="form-control" type="" id="region" name="region_id" <?= ((isset($show)) ? 'disabled' : '' ) ?>>
                                    <?php foreach ($regions as $reg): ?>
                                        <option <?= (($reg->id === $instance->region_id) ? 'selected' : '') ?> value="<?= $reg->id ?>"><?= $reg->name ?></option>
                                    <?php endforeach; ?>

                                </select>

                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">Uso declarado</label>
                            <div class="col-md-8">

                                <select value="" class="form-control" type="" id="use_declared_id" name="use_declared_id" <?= ((isset($show)) ? 'disabled' : '') ?> >
                                    <?php foreach ($uses_declared as $use_declared): ?>
                                        <option <?= (($use_declared->id === $instance->use_declared_id) ? 'selected' : '') ?> value="<?= $use_declared->id ?>"><?= $use_declared->name ?></option>
                                    <?php endforeach; ?>
                                </select>

                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">Uso concreto</label>
                            <div class="col-md-8">
                                <select value="" class="form-control" type="" id="use_concrete_id" name="use_concrete_id" <?= ((isset($show)) ? 'disabled' : '') ?>>
                                </select>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">Mes declarado</label>
                            <div class="col-md-8">

                                <input id="declaration_month" class="form-control" required="true" type="number" min="1" max="12" value="<?= $instance->declaration_month ?>" name="declaration_month" <?= ((isset($show)) ? 'disabled' : '') ?>>

                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">Mes Desde</label>
                            <div class="col-md-8">

                                <input id="month_from" class="form-control" required="true" type="number" min="-12" max="12" value="<?= $instance->month_from ?>" name="month_from" <?= ((isset($show)) ? 'disabled' : '') ?>>

                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">Mes Hasta</label>
                            <div class="col-md-8">

                                <input id="month_to" class="form-control" required="true" type="number" min="-12" max="12" value="<?= $instance->month_to ?>" name="month_to" <?= ((isset($show)) ? 'disabled' : '') ?>>

                            </div>
                        </div>

                        <br>
                        <?php if (isset($show)): ?>
                            <a class="btn btn-default btn-sm" href="<?= $url_edit . '/' . $instance->id() ?>">
                                <span class="glyphicon glyphicon-pencil"></span> <?= lang('Editar') ?>
                            </a>
                        <?php else: ?>
                            <button type="submit" class="btn btn-default" value="save" id="submmit_button" >
                                <span class="glyphicon glyphicon-save"></span> <?= lang('Grabar') ?>
                            </button>

                            <a class="btn btn-default btn-md" href="<?= $url_import ?>">
                                <span class="glyphicon glyphicon-import"></span> <?= lang('Importar desde Archivo') ?>
                            </a>
                        <?php endif; ?>
                    </form>
                </div>
            </div>
        </div>
        <div class="col-md-4" id="asdfa">
            <?php foreach ($instance->errors() as $each): ?>
                <div class="alert alert-danger">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <strong><?= 'Error' ?>!</strong> <?= $each ?>
                </div>
            <?php endforeach; ?>
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
    </div>

</div>

<script>

//LLAMO A AJAX
    var instance = '';

    $('#use_declared_id').change(function (e) {
        e.preventDefault();

        var ajax_read_dir = '<?= $select_concretes ?>';
        instance = '<?= $instance->use_concrete_id ?>';
        var row_val = $(this).val();

        var use_concrete = $("#use_concrete_id");

        $.ajax({
            url: ajax_read_dir + row_val,
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
                use_concrete.html("");
                //cargo combo use_concret
                for (var i = 0; i < res.length; i++) {
                    hola = $('<option>').text(res[i].name).attr('value', res[i].id);
                    if (res[i].id == instance)
                        hola.attr('selected', 'selected');
                    $('#use_concrete_id').append(hola);
                }
            }
        });
    }).change();

</script>
