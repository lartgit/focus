<div class="row">
   <h3>
      <?= lang('usuarios_del_grupo') ?>
      <?= ($instance->display_value()) ? ' > ' . $instance->display_value() : '' ?>
   </h3>
   
   <a class="btn btn-default btn-sm" href="<?= $url_index ?>">
      <span class="glyphicon glyphicon-arrow-left"></span> Volver
   </a>
   
   <br>
   <br>
   
   <div class="row">
      <div class="col-md-4">

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
                        <?= $each->name  ?>
                     </td>
                     <td class="signal">
                        <a href="<?= $url_manage_users . '/' . $instance->primary_key_value() . '/' . $each->primary_key_value() ?>">
                           <span class="glyphicon glyphicon-plus"></span>
                        </a>
                     </td>   
                  </tr>
               <?php endforeach; ?>
            </table>
         </div>

      </div>
      <div class="col-md-4">

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
                        <?= $each->name  ?>
                     </td>
                     <td class="signal">
                        <a href="<?= $url_manage_users . '/' . $instance->primary_key_value() . '/' . $each->primary_key_value() ?>">
                           <span class="glyphicon glyphicon-minus"></span>
                        </a>
                     </td>   
                  </tr>
               <?php endforeach; ?>
            </table>
         </div>

      </div>
   </div>
   <br>
