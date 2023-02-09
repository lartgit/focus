<div class="row">
    <h3>
        <?= lang($managed_class::class_plural_name()) ?>
        <?= ($instance->display_value()) ? ' > ' . $instance->display_value() : '' ?>
    </h3>

    <div class="row">
        <div class="col-md-8">
            <?php if (isset($url_back)) : ?>
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
                    <form role="form" action="<?= $url_action ?>" method="post" class="form-horizontal" <?php if (isset($show)) echo 'disabled=true' ?>>
                        <input type="hidden" value="<?= $instance->id ?>" name="id">
                        <div class="form-group">
                            <label for="client_id" class="col-md-4 control-label">Cliente</label>
                            <div class="col-md-8">

                                <select value="" class="form-control" type="" id="client_id" name="client_id" <?php if (isset($show)) echo 'disabled' ?>>
                                    <?php foreach ($clients as $each) : ?>
                                        <option <?php if ($each->id === $instance->client_id) echo 'selected' ?> value="<?= $each->id ?>"><?= $each->name ?></option>
                                    <?php endforeach; ?>
                                </select>

                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">(Proyecto/Subproyecto)/Versi&oacute;n</label>
                            <div class="col-md-8">

                                <select value="" class="form-control" type="" id="version_id" name="version_id" <?php if (isset($show)) echo 'disabled' ?>>
                                    <?php foreach ($versions as $each) : ?>
                                        <option <?php if ($each->id === $instance->version_id) echo 'selected' ?> value="<?= $each->id ?>"><?= $each->name ?></option>
                                    <?php endforeach; ?>
                                </select>

                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">Tipo de Imagen</label>
                            <div class="col-md-8">
                                <select class="form-control" type="" id="imagen_type_id" name="imagen_type_id" <?php if (isset($show)) echo 'disabled' ?>>
                                    <?php foreach ($imagen_types as $each) : ?>
                                        <option <?= ($each->id === $instance->imagen_type_id) ? 'selected' : "" ?> value="<?= $each->id ?>"><?= $each->name ?></option>
                                    <?php endforeach; ?>
                                </select>
                                <script>
                                    $("#imagen_type_id").change(function(e) {
                                        fetch("<?= site_url(["api", "Pixel_sets", "for_imagen_type"]) ?>?imagen_type_id=" + this.value).then(async (res) => {
                                            let json = await res.json();

                                            $("#set_id").empty();
                                            for (const x of json) {
                                                $("#set_id").append(`<option value="${x.id}" ${x.id == '<?= $instance->set_id ?>' ? "selected" : ""}>${x.name}</option>`)
                                            }
                                        });
                                    });
                                </script>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">Escena <small>(pixeles de salida)</small></label>
                            <div class="col-md-8">
                                <select class="form-control" type="" id="set_id" name="set_id" <?php if (isset($show)) echo 'disabled' ?>></select>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">Regla de Selección de Píxeles</label>
                            <div class="col-md-8">

                                <select value="" class="form-control" type="" id="pixel_selection_rules_id" name="pixel_selection_rules_id" <?php if (isset($show)) echo 'disabled' ?>>
                                    <?php foreach ($px_rules as $each) : ?>
                                        <option <?php if ($each->id === $instance->pixel_selection_rules_id) echo 'selected' ?> value="<?= $each->id ?>"><?= $each->name ?></option>
                                    <?php endforeach; ?>
                                </select>

                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">Nombre</label>
                            <div class="col-md-8">
                                <input class="form-control" value="<?= $instance->name ?>" id="name" name="name" required>
                            </div>
                        </div>

                        <br>
                        <?php if (isset($show)) : ?>
                            <a class="btn btn-default btn-sm" href="<?= $url_edit . '/' . $instance->id() ?>">
                                <span class="glyphicon glyphicon-pencil"></span> <?= lang('Editar') ?>
                            </a>
                        <?php else : ?>
                            <button type="submit" class="btn btn-default" value="save" id="submmit_button">
                                <span class="glyphicon glyphicon-save"></span> <?= lang('Grabar') ?>
                            </button>
                        <?php endif; ?>
                    </form>
                </div>
            </div>
        </div>
        <div class="col-md-4" id="asdfa">
            <?php foreach ($instance->errors() as $each) : ?>
                <div class="alert alert-danger">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <strong><?= lang('Error') ?>!</strong> <?= $each ?>
                </div>
            <?php endforeach; ?>
            <?php if (isset($error_string)) : foreach ($errors as $error) : ?>
                    <div class="error-string alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($error) ?>
                    </div>
            <?php endforeach;
            endif; ?>
            <div id="errors"></div>

            <?php if (isset($success)) : foreach ($success as $message) : ?>
                    <div class="succes-string alert alert-success">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($message) ?>
                    </div>
                    <br />
            <?php endforeach;
            endif; ?>
        </div>
        <?php if (!isset($show)) : ?>
            <div class="col-md-4" id="proy_tree">
                <div class="panel panel-info">
                    <div class="panel-heading">
                        <h3 class="panel-title">Proyectos</h3>
                    </div>
                    <div class="panel-body">
                        <?= $Project->spit_tree($obj_tree, 'tree2'); ?>
                    </div>
                </div>
                <!-- end col - md -->
            </div>
        <?php endif; ?>

    </div>

</div>

<script>
    $(function() {
        var instance = '';
        /*Star ajax call for */
        /*Traemos por ajax el combo de versiones en base al cliente seleccionado*/
        $('#client_id').change(function(e) {
            e.preventDefault();

            var ajax_read_dir = '<?= $url_select_versions ?>';

            var row_val = $(this).val();

            var version = $("#version_id");

            instance = '<?= $instance->version_id ?>';
            $.ajax({
                url: ajax_read_dir,
                type: "POST",
                data: {
                    client: row_val
                },
                dataType: "json",
                beforeSend: function() {
                    $("#square").html('Cargando');
                },
                error: function(res) {
                    console.log("error" + res);
                },
                success: function(res) {
                    // Limpiamos el select
                    version.innerHTML = "";
                    version.html("");
                    //cargo combo
                    if (res.result.length == 0) {
                        /*Agrego esta opciones para evitar dejar el combo en blanco y advertir al cliente*/
                        $('#version_id').append('<option>NO HAY VERSIONES DE LOS PROYECTOS DE CLIENTE</option>');
                    } else {
                        for (var i = 0; i < res.result.length; i++) {
                            opt = $('<option>').text(res.result[i].proyname + ' / ' + res.result[i].name).attr('value', res.result[i].id);
                            if (res.result[i].id == instance) opt.attr('selected', 'selected');
                            $('#version_id').append(opt);
                        }
                    }

                    /*Cargar la vista parcial*/
                    $('#proy_tree').html('');
                    $('#proy_tree').append(res.tree);
                    $.fn.extend({
                        treed: function(o) {

                            var openedClass = 'glyphicon-minus-sign';
                            var closedClass = 'glyphicon-plus-sign';

                            if (typeof o != 'undefined') {
                                if (typeof o.openedClass != 'undefined') {
                                    openedClass = o.openedClass;
                                }
                                if (typeof o.closedClass != 'undefined') {
                                    closedClass = o.closedClass;
                                }
                            };

                            //initialize each of the top levels
                            var tree = $(this);
                            tree.addClass("tree");
                            tree.find('li').has("ul").each(function() {
                                var branch = $(this); //li with children ul
                                branch.prepend("<i class='indicator glyphicon " + closedClass + "'></i>");
                                branch.addClass('branch');
                                branch.on('click', function(e) {
                                    if (this == e.target) {
                                        var icon = $(this).children('i:first');
                                        icon.toggleClass(openedClass + " " + closedClass);
                                        $(this).children().children().toggle();
                                    }
                                })
                                branch.children().children().toggle();
                            });
                            //fire event from the dynamically added icon
                            tree.find('.branch .indicator').each(function() {
                                $(this).on('click', function() {
                                    $(this).closest('li').click();
                                });
                            });
                            //fire event to open branch if the li contains an anchor instead of text
                            tree.find('.branch>a').each(function() {
                                $(this).on('click', function(e) {
                                    $(this).closest('li').click();
                                    e.preventDefault();
                                });
                            });
                            //fire event to open branch if the li contains a button instead of text
                            tree.find('.branch>button').each(function() {
                                $(this).on('click', function(e) {
                                    $(this).closest('li').click();
                                    e.preventDefault();
                                });
                            });
                        }
                    });

                    $('.version_node').tooltip({
                        title: "version"
                    });
                    //Initialization of treeviews
                    $('#tree2').treed();
                    /*End Carga vista parcial*/
                }
            });
        }).change();
        /*End ajax call*/

        $('.version_node').click(function() {
            $("select[name=project_id]").val($(this).attr('data-value'));
            $('#version_id').val($(this).attr('data-name'));
            $('#version_id').val($(this).attr('data-value'));
        });
        $('.version_node').tooltip({
            title: "version"
        });

    });


    $.fn.extend({
        treed: function(o) {

            var openedClass = 'glyphicon-minus-sign';
            var closedClass = 'glyphicon-plus-sign';

            if (typeof o != 'undefined') {
                if (typeof o.openedClass != 'undefined') {
                    openedClass = o.openedClass;
                }
                if (typeof o.closedClass != 'undefined') {
                    closedClass = o.closedClass;
                }
            };

            //initialize each of the top levels
            var tree = $(this);
            tree.addClass("tree");
            tree.find('li').has("ul").each(function() {
                var branch = $(this); //li with children ul
                branch.prepend("<i class='indicator glyphicon " + closedClass + "'></i>");
                branch.addClass('branch');
                branch.on('click', function(e) {
                    if (this == e.target) {
                        var icon = $(this).children('i:first');
                        icon.toggleClass(openedClass + " " + closedClass);
                        $(this).children().children().toggle();
                    }
                })
                branch.children().children().toggle();
            });
            //fire event from the dynamically added icon
            tree.find('.branch .indicator').each(function() {
                $(this).on('click', function() {
                    $(this).closest('li').click();
                });
            });
            //fire event to open branch if the li contains an anchor instead of text
            tree.find('.branch>a').each(function() {
                $(this).on('click', function(e) {
                    $(this).closest('li').click();
                    e.preventDefault();
                });
            });
            //fire event to open branch if the li contains a button instead of text
            tree.find('.branch>button').each(function() {
                $(this).on('click', function(e) {
                    $(this).closest('li').click();
                    e.preventDefault();
                });
            });
        }
    });

    //Initialization of treeviews

    $('#tree2').treed();
</script>