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
   </div>
   <br>

   <div class="row">
      <div class="col-md-8">
         <div class="panel panel-default">
            <div class="panel-body">
               <form role="form" action="<?= $url_action ?>" method="post" class="form-horizontal">
                    <input type="hidden" value="<?= $instance->id ?>" name="id">
                    <div class="form-group">
                        <label class="col-md-4 control-label">Nombre</label>
                        <div class="col-md-8">
                            <input class="form-control" value="<?= $instance->name ?>" id="name" name="name" <?= ((($show)) ? 'disabled' : '') ?> required>
                        </div>
                    </div>
                     <div class="form-group">
                        <label class="col-md-4 control-label">Cliente</label>
                        <div class="col-md-8" id="client">
                            <select value="" class="form-control" type="" id="client_id" <?= ((($show)) ? 'disabled' : '') ?>>
                                <?php foreach ($clients as $each): ?>
                                    <option <?= ((isset($client_project) && $each->id == $client_project->client_id) ? 'selected' : '') ?> value="<?= $each->id ?>"><?= $each->name ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-md-4 control-label">Proyecto</label>
                            <div class="col-md-8">
                                <select data-name="<?= $instance->project_id ?>" value="" class="form-control" type="" id="project_id" name="project_id" <?= ((($show)) ? 'disabled' : '') ?> >
                                    <option value="">N/A</option>
                                    <?php foreach ($projects as $each): ?>
                                        <?php
                                        if ($each->id == $instance->id) {
                                            continue;
                                        }
                                        ?>
                                        <option <?= (($each->id == $instance->project_id) ? 'selected' : '') ?>  value="<?= $each->id ?>"><?= $each->name ?></option>
                                    <?php endforeach; ?>
                                </select>

                            </div>
                        </div>
                        <div class="form-group">

                            <label class="col-md-4 control-label" for="active">Active</label>
                            <div class="col-md-8">
                                <input name="active" value="false" type="hidden">
                                <input type="checkbox" id="active" name="active" <?= ((($show)) ? 'disabled' : '') ?> <?= (($instance->active == 't') ? 'checked' : '') ?>>

                            </div>
                        </div>
                  <br>
                  <?php if ($show): ?>
                     <a class="btn btn-default btn-sm" href="<?= $url_edit . '/' . $instance->id() ?>">
                        <span class="glyphicon glyphicon-pencil"></span> <?= lang('Editar') ?>
                     </a>
                  <?php else: ?>
                     <button type="submit" class="btn btn-default">
                        <span class="glyphicon glyphicon-save"></span> <?= lang('Grabar') ?>
                     </button>
                  <?php endif; ?>
               </form>
            </div>
         </div>
      </div>
      <div class="col-md-4">
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
      <div class="col-md-4" id="asdfa">
         <?php foreach ($instance->errors() as $each): ?>
            <div class="alert alert-danger">
               <button type="button" class="close" data-dismiss="alert">&times;</button>
               <strong><?= lang('Error') ?>!</strong> <?= $each ?>
            </div>
         <?php endforeach; ?>
      </div>
      <?php if (!$show): ?>
        <div class="col-md-4">
            <div class="panel panel-info">
                <div class="panel-heading">
                    <h3 class="panel-title">Proyectos</h3>
                </div>
                <div class="panel-body">
                    <?=$Project->spit_tree($obj_tree,'tree2'); ?>
                </div>
            </div>
        <!-- end col - md -->
        </div>
        <?php endif;?>
   </div>

</div>

<script type="text/javascript">
    $(function () {
        $("#client_id").change(function (e) {
            e.preventDefault();
            var project_id = '<?= $instance->project_id ?>';
            var row_val = $(this).val();
            var parent = $("[name=project_id]");
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
                            if (res['projects'][i]['id'] == project_id)
                                combo.attr('selected', 'selected');
                            parent.append(combo);
                        }
                        tree.html('');
                        tree.append(res['p']);
                        $('#tree2').treed();

                        <?php if(!isset($show)): ?>
                        $('.ref').click(function () {
                            $("select[name=project_id]").val($(this).attr('data-value'));
                            $('#project').val($(this).attr('data-name'));
                            $('#project_id').val($(this).attr('data-value'));
                            $('#project_id').change();
                        });
                        <?php endif; ?>
                    }
                });
            }
        }).change();
    });

$(function(){

    $('.ref').click(function(){
        $("select[name=project_id]").val($(this).attr('data-value'));
        $('#project').val($(this).attr('data-name'));
        $('#project_id').val($(this).attr('data-value'));
    });

    // $('.project_node').tooltip({title: ""});
    $('.version_node').tooltip({title: "version"});

});


$.fn.extend({
    treed: function (o) {

      var openedClass = 'glyphicon-minus-sign';
      var closedClass = 'glyphicon-plus-sign';

      if (typeof o != 'undefined'){
        if (typeof o.openedClass != 'undefined'){
        openedClass = o.openedClass;
        }
        if (typeof o.closedClass != 'undefined'){
        closedClass = o.closedClass;
        }
      };

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
      tree.find('.branch .indicator').each(function(){
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

$('#tree2').treed();

</script>