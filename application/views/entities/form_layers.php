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
        <?php foreach ($instance->errors() as $each): ?>
            <div class="alert alert-danger">
                <button type="button" class="close" data-dismiss="alert">&times;</button>
                <strong><?= lang('Error') ?>!</strong> <?= lang($each) ?>
            </div>
        <?php endforeach; ?>
        <?php if (isset($error_string)): foreach ($errors as $error): ?>
            <div class="error-string alert alert-danger">
                <button type="button" class="close" data-dismiss="alert">&times;</button>
                <?= lang($error) ?>
            </div>
        <?php endforeach; endif; ?>
        <div id="errors"></div>

        <?php if (isset($success)): foreach ($success as $message): ?>
            <div class="succes-string alert alert-success">
                <button type="button" class="close" data-dismiss="alert">&times;</button>
                <?= lang($message) ?>
            </div>
            <br />
        <?php endforeach; endif; ?>
      </div>
   </div>
   <br>

   <div class="row">
      <div class="col-md-6">
         <div class="panel panel-default">
            <div class="panel-body">
                <form role="form" action="<?= $url_action ?>" method="post" class="form-horizontal">
                    <input type="hidden" name="id" value="<?=$instance->id?>" />
                    <div class="form-group">
                        <label class="col-md-4 control-label">Nombre</label>
                        <div class="col-md-8">
                            <input class="form-control" value="<?=$instance->name?>" id="name" name="name" required <?php if (isset($show)) echo 'disabled' ?>>
                        </div>
                    </div>    
                    <div class="form-group">
                        <label class="col-md-4 control-label">Tipo de Imagen</label>
                        <div class="col-md-8">
                            <select value="" class="form-control" type="" id="image_type_id" name="image_type_id" required <?php if (isset($show)) echo 'disabled' ?>>
                                    <?php foreach ($imagen_types as $each): ?>
                                        <option <?php if ($each->id === $instance->image_type_id) echo 'selected' ?> value="<?= $each->id ?>"><?= $each->name ?></option>
                                    <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                   <div class="form-group">
                        <label class="col-md-4 control-label">Tipo de Dato</label>
                        <div class="col-md-8">
                            <select value="" class="form-control" type="" id="parameter_type_id" name="parameter_type_id" required <?php if (isset($show)) echo 'disabled' ?>>
                                    <?php foreach ($data_types as $each): ?>
                                        <option <?php if ($each->id === $instance->parameter_type_id) echo 'selected' ?> value="<?= $each->id ?>"><?= $each->name ?></option>
                                    <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                       
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
   </div>

</div>