<div class="row">
    <h3><?= lang($managed_class::class_plural_name()) ?></h3>

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
                    <span class="glyphicon glyphicon-plus"></span> <?= lang('Agregar') ?>
                </a>
            <?php endif; ?>
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

    </div>
    <br>
    <div class="row">
        <div class="col-md-8">
            <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed">
                <thead>
                    <tr class="info">
                        <?php if ($controller->is_developing_mode()): ?>
                            <th>Id</th>
                        <?php endif; ?>
                        <th>Cliente/Proyecto/Version</th>
                        <?php if ($user_can_edit): ?>
                            <th>Editar</th>
                        <?php endif; ?>
                        <?php if ($user_can_delete): ?>
                            <th>Borrar</th>
                        <?php endif; ?>
                        <?php if ($managed_class::class_ts_column()): ?>
                            <th>Fecha de Alta</th>
                        <?php endif; ?>

                        <?php if ($managed_class::class_created_at_column()): ?>
                            <th>Última Modificación</th>
                        <?php endif; ?>

                    </tr>
                </thead>

                <tbody>

                    <?php foreach ($instances as $instance): ?>
                        <tr>
                            <?php if ($controller->is_developing_mode()): ?>
                                <td><?= $instance->id ?></td>
                            <?php endif; ?>

                            <td style="padding-left: 20px;
                                text-align: center; 
                                <?php echo (!$instance->is_active()) ? 'text-decoration: line-through;' : '' ?>
                                " title="<?=$instance->cli_proy_name() ?>"
                                >
                                <a href="<?= $url_show . '/' . $instance->id() ?>">
                                    <?= $instance->cli_proy_name() ?>
                                </a>

                            </td>
                            <?php if ($user_can_edit): ?>
                                <td>
                                    <a href="<?= $url_edit . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-pencil"></span> </a>
                                </td>                     
                            <?php endif; ?>
                            <?php if ($user_can_delete): ?>
                                <td>
                                    <a href="<?= $url_delete . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-remove red"></span> </a>
                                </td>
                            <?php endif; ?>

                            <?php if ($managed_class::class_created_at_column()): ?>
                                <td><?= $instance->created_at() ?></td>
                            <?php endif; ?>

                            <?php if ($managed_class::class_ts_column()): ?>
                                <td><?= $instance->ts ?></td>
                            <?php endif; ?>

                        </tr>
                    <?php endforeach; ?>
                </tbody>

                <tfoot>
                </tfoot>
            </table>
        </div>
        <!-- End Div -->
        <div class="col-md-4">
            <div class="panel panel-info">
                <div class="panel-heading">
                    <h3 class="panel-title"><?= lang('Proyectos') ?></h3>
                </div>
                <div class="panel-body">            
                    <?= $Project->spit_tree($obj_tree, 'tree2'); ?>
                </div>
            </div>
            <!-- end col - md -->            
        </div>

    </div>
</div>

<script type="text/javascript">

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