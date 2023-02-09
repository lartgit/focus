<div id="page-body">
   <h3>
      <?= $class::class_plural_name() ?>
      <?= ($instance->display_value()) ? ' > '. $instance->display_value() : '' ?>
   </h3>

   <div class="row">
      <div class="col-md-12">
         <?php if (isset($url_return)): ?>
            <a class="btn btn-default btn-sm" href="<?= $url_return ?>">
               <span class="glyphicon glyphicon-arrow-left"></span> Volver
            </a>
         <?php else: ?>        
            <a class="btn btn-default btn-sm" href="<?= $url_entity_manage . $class::class_name() ?>">
               <span class="glyphicon glyphicon-arrow-left"></span> Volver
            </a>
         <?php endif; ?>

      </div>
   </div>
   <br>

   <div class="row">
      <div class="col-md-4">
         <div class="panel panel-default">
            <div class="panel-body">
               <form role="form" action="<?= $url_action . $class::class_name() ?>" method="post" class="form-horizontal">
                  <?= $form_content ?>
                  <br>
                  <?php if (isset($show)): ?>
                     <a class="btn btn-default btn-sm" href="<?= $url_edit . $instance->class_name() . '/' . $instance->primary_key_value() ?>">
                        <span class="glyphicon glyphicon-pencil"></span> Editar
                     </a>
                  <? else: ?>
                     <button type="submit" class="btn btn-default">
                        <span class="glyphicon glyphicon-save"></span> Grabar
                     </button>
                  <? endif; ?>
               </form>
            </div>
         </div>
      </div>
      <div class="col-md-4" id="asdfa">
         <?php if (sizeof($instance->errors) > 0): ?>
            <?php foreach ($instance->errors as $each): ?>
               <div class="alert alert-danger">
                  <button type="button" class="close" data-dismiss="alert">&times;</button>
                  <strong>Error!</strong> <?= $each ?>
               </div>
            <?php endforeach; ?>
         <?php endif; ?>
      </div>
   </div>
</div>
    <div class="col-md-4">
                <div class="form-group">
                    <label class="col-md-4 control-label">Path</label>
                    <div class="col-md-8">
                        <div class="input-group">
                            <input value="" class="form-control" type="text" id="path" name="path" readonly>
                            <span class="input-group-btn">
                                <button type="button" class="btn btn-primary" data-toggle="modal" data-target=".bs-example-modal-md" id="btn-sel">Seleccionar</button>
                            </span>
                        </div>   
                    </div>
                </div>
<div class="form-group">
                    <label class="col-md-4 control-label">Path</label>
                    <div class="col-md-8">
                        <div class="input-group">
                            <input value="" class="form-control" type="text" id="path" name="path" value="<?=$instance->campo ?>"readonly>
                            <span class="input-group-btn">
                                <button type="button" class="btn btn-primary" data-toggle="modal" data-target=".bs-example-modal-md" id="btn-sel">Seleccionar</button>
                            </span>
                        </div>   
                    </div>
                </div>                
    </div>          
