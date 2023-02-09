<div class="row">
    <h3>
        <?= lang($managed_class::class_plural_name()) ?>
        <?= ($instance->display_value()) ? ' > ' . $instance->display_value() : '' ?>
    </h3>

    <div class="row">
        <div class="col-md-12">
            <?php if (isset($url_back)): ?>
                <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
                    <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                </a>
            <?php endif; ?>
        </div>
    </div>
    <br>

    <div class="row">
        <div class="col-md-8">
            <div class="panel panel-default">
                <div class="panel-body">
                    <form role="form" method="post" class="form-horizontal">
                        <br>
                        <?php if (isset($instance->notice)): ?>
                            <div class="alert alert-danger">
                                <?= $instance->notice ?>
                                <br>
                                <br>
                                <?php if ($instance->is_deleteable()): ?>
                                    <?php if (!empty($related_instances)): ?>
                                        <?php if (is_array($related_instances)): ?>
                                            <?php foreach ($related_instances as $each_related): ?>
                                                <?php if (!empty($each_related)): ?>
                                                    <div class="panel" >
                                                        <?= lang('También se borrarán las entidades relacionadas :') ?>
                                                        <?= $each_related[0]->class_plural_name() ?>
                                                        <br>
                                                        <?php foreach ($each_related as $each_instance): ?>
                                                            <span class="glyphicon glyphicon-minus"></span> <?= $each_instance->display_value() ?><br>
                                                        <?php endforeach; ?>
                                                        <br>
                                                    </div>
                                                <?php endif; ?>
                                            <?php endforeach; ?>
                                        <?php else: ?>
                                            <div class="panel" >
                                                <?= lang('También se borrarán los ') ?> <?= $related_instances[0]->class_plural_name() ?> <?= lang(' relacionados') ?>
                                                <br>
                                                <?php foreach ($related_instances as $each_instance): ?>
                                                    <span class="glyphicon glyphicon-minus"></span> <?= $each_instance->display_value() ?><br>
                                                <?php endforeach; ?>
                                                <br>
                                            </div>
                                        <?php endif; ?>
                                    <?php endif; ?>
                                    <button type="submit" name="submited" class="btn btn-default">
                                        <span class="glyphicon glyphicon-remove"></span> <?= lang('Eliminar') ?>
                                    </button>
                                <?php endif; ?>
                            </div>
                        <?php endif; ?>
                    </form>
                </div>
            </div>
        </div>
        <div class="col-md-4" id="asdfa">
            <?php foreach ($instance->errors() as $each): ?>
                <div class="alert alert-danger">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <strong>Error!</strong> <?= lang($each) ?>
                </div>
            <?php endforeach; ?>
        </div>
    </div>

</div>
