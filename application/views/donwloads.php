<div class="row">
    <div class="col-lg-12">
        <h3 class="page-header"> <?= lang('Descargas') ?></h3>
    </div>
    <!-- /.col-lg-12 -->
</div>
<div class="row">
    <div class="col-md-4">
        <?php if (isset($error_string)) : foreach ($errors as $error) : ?>
                <div class="error-string alert alert-danger">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <?= $error ?>
                </div>
        <?php endforeach;
        endif; ?>
        <div id="errors"></div>

        <?php if (isset($success)) : foreach ($success as $message) : ?>
                <div class="succes-string alert alert-success">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <?= $message ?>
                </div>
                <br />
        <?php endforeach;
        endif; ?>
    </div>
</div>
<!-- /.row -->
<div class="row">
    <div class="col-lg-6">
        <div class="panel panel-default">
            <div class="panel-heading">
                <i class="fa fa-bar-chart-o fa-fw"></i> <?= lang('Procesos') ?>
                <div class="pull-right">
                    <div class="btn-group">
                        <button type="button" class="btn btn-default btn-xs dropdown-toggle" data-toggle="dropdown">
                            <?= lang('Actions') ?>
                            <span class="caret"></span>
                        </button>
                        <ul class="dropdown-menu pull-right" role="menu">
                            <li><a href="<?= $url_process_results ?>"><?= lang('Gestor de Relaciones de Importación') ?></a>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
            <!-- /.panel-heading -->
            <div class="panel-body">
                <div id="morris-area-chart"></div>
                <form role="form" action="<?= $url_dowdload_process ?>" method="post" class="form-horizontal">
                    <br>
                    <div class="form-group">
                        <label for="process_id" class="col-md-4 control-label"><?= lang('Relacion de Exportacion') ?> </label>
                        <div class="col-md-8">
                            <select class="form-control" name="process_id">
                                <?php foreach ($instance->processed_results() as $process) : ?>
                                    <option value="<?= $process->id ?>"><?= $process->name ?></option>
                                <?php endforeach; ?>
                            </select>
                            <br>

                            <div class="alert alert-info">
                                <div class="panel-body">
                                    <label class="control-label">
                                        <?= lang('Formato de Salida') ?></label>
                                    <br>
                                    <br>
                                    <input type="radio" name="input_file_format" value="csv"> Csv <br>
                                    <input type="radio" name="input_file_format" value="excel"> Excel <br>
                                </div>
                            </div>
                        </div>
                    </div>

                    <br>
                    <button type="submit" class="btn btn-default">
                        <span class="glyphicon glyphicon-save"></span> <?= lang('Descargar') ?>
                    </button>
                </form>
            </div>
            <!-- /.panel-body -->
        </div>
        <!-- /.panel -->

        <div id=""></div>
        <!-- /.panel -->
        <!-- /.panel -->
    </div>
    <!-- /.col-lg-8 -->
    <div class="col-lg-6">
        <div class="panel panel-default">
            <div class="panel-heading">
                <i class="fa fa-bell fa-fw"></i> <?= lang('Relaciones de Importación procesadas') ?>
            </div>
            <!-- /.panel-heading -->
            <div class="table-responsive">
                <table class="table table-bordered table-hover table-striped">
                    <thead>
                        <tr>
                            <th><?= lang('Nombre') ?></th>
                            <th><?= lang('Set de Pixeles') ?></th>
                            <th><?= lang('Date') ?></th>
                            <th><?= lang('Version') ?></th>
                            <th><?= lang('Regla de Selección de Pixeles') ?></th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($instance->processed_results() as $process) : ?>
                            <tr>
                                <td><?= $process->name ?></td>
                                <td><?= $process->imagen_type_name ?></td>
                                <td><?= $process->date_time ?></td>
                                <td><?= $process->version_name ?></td>
                                <td><?= $process->px_rule_name ?></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
            <!-- /.table-responsive -->
            <!-- /.panel-body -->
        </div>
        <!-- /.panel -->


    </div>
    <!-- /.col-lg-4 -->
</div>
<!-- /.row -->