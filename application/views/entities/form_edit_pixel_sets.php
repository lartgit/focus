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
        <?php endforeach; endif; ?>
        <div id="errors"></div>

        <?php if (isset($success)): foreach ($success as $message): ?>
            <div class="succes-string alert alert-success">
                <button type="button" class="close" data-dismiss="alert">&times;</button>
                <?= $message ?>
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
                    <input value="<?=$instance->id?>" type="hidden" name="id">
                    <div class="form-group">
                        <label class="col-md-4 control-label">Nombre</label>
                        <div class="col-md-8">
                            <input class="form-control" value="<?=$instance->name?>" id="name" name="name" required <?php if (isset($show)) echo 'disabled' ?>>
                        </div>
                    </div>    
                    <div class="form-group">
                        <label class="col-md-4 control-label">Tipo de Imagen</label>
                        <div class="col-md-8">
                            <select value="" class="form-control" type="" id="imagen_type_id" name="imagen_type_id" required <?php if (isset($show)) echo 'disabled' ?>>
                                    <?php foreach ($imagen_types as $each): ?>
                                        <option <?php if ($each->id === $instance->imagen_type_id) echo 'selected' ?> value="<?= $each->id ?>"><?= $each->name ?></option>
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