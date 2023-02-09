<style>
    .relations_panel {
        height:500px;
        overflow: scroll;
    }    
</style>
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
        <div class="col-md-4">
            <div class="panel panel-default">
                <div class="panel-body">
                    <form role="form" action="<?= $url_action ?>" method="post" class="form-horizontal">
                        <?= $form_content ?>
                        <br>
<?php if (isset($show)): ?>
                            <a class="btn btn-default btn-sm" href="<?= $url_edit . '/' . $instance->id() ?>">
                                <span class="glyphicon glyphicon-pencil"></span> <?= lang('Editar') ?>
                            </a>
<?php else: ?>
                            <button type="submit" class="btn btn-default" id="submmit_button" >
                                <span class="glyphicon glyphicon-save"></span> <?= lang('Grabar') ?>
                            </button>
<?php endif; ?>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-md-4">
            <div class="panel panel-default">
                <div class="panel-body relations_panel">
                    <h3>
                        <?= lang('Usuarios del Grupo') ?>
                        >
<?= ($instance->display_value()) ?>
                    </h3>

                    <div class="row">
                        <div class="col-md-6">

                            <div class="panel panel-info">
                                <!-- Default panel contents -->
                                <div class="panel-heading">
<?= lang('Disponibles') ?>
                                </div>

                                <!-- Table -->
                                <table class="table table_elipsis">
                                            <?php foreach ($instance->available_users() as $each): ?>
                                        <tr>
                                            <td>
    <?= $each->name ?>
                                            </td>
                                            <td class="signal">
                                                <a href="<?= $url_manage_users_edit . '/' . $instance->primary_key_value() . '/' . $each->primary_key_value() ?>">
                                                    <span class="glyphicon glyphicon-plus"></span>
                                                </a>
                                            </td>   
                                        </tr>
<?php endforeach; ?>
                                </table>
                            </div>

                        </div>
                        <div class="col-md-6">

                            <div class="panel panel-success">
                                <!-- Default panel contents -->
                                <div class="panel-heading">
<?= lang('Asignados') ?>
                                </div>

                                <!-- Table -->
                                <table class="table table_elipsis">
                                            <?php foreach ($instance->users() as $each): ?>
                                        <tr>
                                            <td>
    <?= $each->name ?>
                                            </td>
                                            <td class="signal">
                                                <a href="<?= $url_manage_users_edit . '/' . $instance->primary_key_value() . '/' . $each->primary_key_value() ?>">
                                                    <span class="glyphicon glyphicon-minus"></span>
                                                </a>
                                            </td>   
                                        </tr>
<?php endforeach; ?>
                                </table>
                            </div>

                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="panel panel-default">
                <div class="panel-body relations_panel" >
                    <h3>
                        <?= lang('Menus Del Grupo') ?>
                        >
<?= ($instance->display_value()) ?>
                    </h3>

                    <div class="row">
                        <div class="col-md-6">

                            <div class="panel panel-info">
                                <!-- Default panel contents -->
                                <div class="panel-heading">
<?= lang('Disponibles') ?>
                                </div>

                                <!-- Table -->
                                <table class="table table_elipsis">
                                            <?php foreach ($instance->available_menus() as $each): ?>
                                        <tr>
                                            <td>
    <?= $each->name ?>
                                            </td>
                                            <td class="signal">
                                                <a href="<?= $url_manage_menus_edit . '/' . $instance->primary_key_value() . '/' . $each->primary_key_value() ?>">
                                                    <span class="glyphicon glyphicon-plus"></span>
                                                </a>
                                            </td>   
                                        </tr>
<?php endforeach; ?>
                                </table>
                            </div>

                        </div>
                        <div class="col-md-6">

                            <div class="panel panel-success">
                                <!-- Default panel contents -->
                                <div class="panel-heading">
<?= lang('Asignados') ?>
                                </div>

                                <!-- Table -->
                                <table class="table table_elipsis">
                                            <?php foreach ($instance->menus() as $each): ?>
                                        <tr>
                                            <td>
    <?= $each->name ?>
                                            </td>
                                            <td class="signal">
                                                <a href="<?= $url_manage_menus_edit . '/' . $instance->primary_key_value() . '/' . $each->primary_key_value() ?>">
                                                    <span class="glyphicon glyphicon-minus"></span>
                                                </a>
                                            </td>   
                                        </tr>
<?php endforeach; ?>
                                </table>
                            </div>

                        </div>
                    </div>
                </div>
            </div>
        </div>

    </div>

</div>