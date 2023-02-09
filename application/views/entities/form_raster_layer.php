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
                            <label class="col-md-4 control-label">Tipo de capa</label>
                            <div class="col-md-8">
                                <select class="form-control" type="" id="layer_type_id" name="layer_type_id" <?= ((($show)) ? 'disabled' : '') ?> >   
                                        <option selected value="<?= $instance->layer_type_id ?>"><?= $instance->layer_type_name ?></option>
                                </select>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">Archivo Raster</label>
                            <div class="col-md-8" id="client">
                                <input class="form-control" value="<?= $instance->raster_file_name ?>" id="raster_file_id" name="raster_file_id" <?= ((($show)) ? 'disabled' : '') ?> required>

                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">Image Date</label>
                            <div class="col-md-8">
                                <input class="form-control" value="<?= $instance->image_date ?>" id="image_date" name="image_date" <?= ((($show)) ? 'disabled' : '') ?> required>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label">Cantidad de Pixels</label>
                            <div class="col-md-8">
                                <input class="form-control" value="<?= $instance->count_pixels ?>" <?= ((($show)) ? 'disabled' : '') ?> required>
                            </div>
                        </div>                        
                        <br>
<!--                        <?php if (($show)): ?>
                            <a class="btn btn-default btn-sm" href="<?= $url_edit . '/' . $instance->id() ?>">
                                <span class="glyphicon glyphicon-pencil"></span> <?= lang('Editar') ?>
                            </a>
                        <?php else: ?>
                            <button type="submit" class="btn btn-default" value="save" id="submmit_button" >
                                <span class="glyphicon glyphicon-save"></span> <?= lang('Grabar') ?>
                            </button>
                        <?php endif; ?> -->
                    </form>
                </div>
            </div>
        </div>
        <div class="col-md-4" id="asdfa">
            <?php foreach ($instance->errors() as $each): ?>
                <div class="alert alert-danger">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <strong><?= lang('Error') ?>!</strong> <?= $each ?>
                </div>
            <?php endforeach; ?>
            <?php if (isset($error_string)): foreach ($errors as $error): ?>
                    <div class="error-string alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($error) ?>
                    </div>
                <?php endforeach;
            endif;
            ?>
            <div id="errors"></div>

<?php if (isset($success)): foreach ($success as $message): ?>
                    <div class="succes-string alert alert-success">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
        <?= lang($message) ?>
                    </div>
                    <br />
                <?php endforeach;
            endif;
            ?>
            <div class="panel panel-info">
                <div class="panel-heading">
                    <h3 class="panel-title">Proyectos</h3>
                </div>
                <div class="panel-body" name="tree">
                    <!--<?= $Project->spit_tree($obj_tree, 'tree2'); ?>-->
                </div>
            </div>
            <!-- end col - md -->
        </div>
    </div>
</div>

<script type="text/javascript">
    $(function () {
        $("[name=client_id]").change(function (e) {
            e.preventDefault();
            var parent_id = '<?= $instance->parent_id ?>';
            var row_val = $(this).val();
            var parent = $("[name=parent_id]");
            var tree = $("[name=tree]");

            if (row_val != '') {
                var ajax_client_project = '<?= $url_ajax_client_project ?>';
                $.ajax({
                    url: ajax_client_project,
                    type: "POST",
                    data: {client: row_val, div_id: 'tree2'},
                    dataType: "json",
                    beforeSend: function () {
                        // $("#square").html('Cargando');
                    },
                    error: function (res) {

                    },
                    success: function (res) {
                        //cargo combo proyectos
                        parent.html("");
                        combo = $('<option>').text('N/A').attr('value', '');
                        parent.append(combo);
                        for (var i = 0; i < res['projects'].length; i++) {
                            combo = $('<option>').text(res['projects'][i]['name']).attr('value', res['projects'][i]['id']);
                            if (res['projects'][i]['id'] == parent_id)
                                combo.attr('selected', 'selected');
                            parent.append(combo);
                        }
                        tree.html('');
                        tree.append(res['p']);
                        $('#tree2').treed();

                        <?php if(!$show): ?>
                        $('.ref').click(function () {
                            $("select[name=parent_id]").val($(this).attr('data-value'));
                            $('#project').val($(this).attr('data-name'));
                            $('#parent_id').val($(this).attr('data-value'));
                            $('#parent_id').change();
                        });
                        <?php endif; ?>
                    }
                });
            }
        }).change();
    });
    $(function () {

        $('.ref').click(function () {
            $("select[name=parent_id]").val($(this).attr('data-value'));
            $('#project').val($(this).attr('data-name'));
            $('#parent_id').val($(this).attr('data-value'));
            $('#parent_id').change();
        });
    });
    $.fn.extend({
        treed: function (o) {

            var openedClass = 'glyphicon-minus-sign';
            var closedClass = 'glyphicon-plus-sign';
            if (typeof o != 'undefined') {
                if (typeof o.openedClass != 'undefined') {
                    openedClass = o.openedClass;
                }
                if (typeof o.closedClass != 'undefined') {
                    closedClass = o.closedClass;
                }
            }
            ;
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
            tree.find('.branch .indicator').each(function () {
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

    // $('#tree2').treed({openedClass: 'glyphicon-folder-open', closedClass: 'glyphicon-folder-close'});
    $('#tree2').treed();

</script>
