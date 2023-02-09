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
                        <?= $form_content ?>
                        <br>
                        <?php if (($show)): ?>
                            <a class="btn btn-default btn-sm" href="<?= $url_edit . '/' . $instance->id() ?>">
                                <span class="glyphicon glyphicon-pencil"></span> <?= lang('Editar') ?>
                            </a>
                        <?php else: ?>
                            <button type="submit" class="btn btn-default" value="save" id="submmit_button" >
                                <span class="glyphicon glyphicon-save"></span> <?= lang('Grabar') ?>
                            </button>
                        <?php endif; ?>
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
                    <?php
                endforeach;
            endif;
            ?>
            <div id="errors"></div>

            <?php if (isset($success)): foreach ($success as $message): ?>
                    <div class="succes-string alert alert-success">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($message) ?>
                    </div>
                    <br />
                    <?php
                endforeach;
            endif;
            ?>
            <div class="panel panel-info">
                <div class="panel-heading">
                    <h3 class="panel-title">Proyectos</h3>
                </div>
                <div class="panel-body">
                    <?= $Farm->spit_tree($obj_tree, 'tree2'); ?>
                </div>
            </div>
            <!-- end col - md -->                    
        </div>
    </div>
</div>

<script type="text/javascript">

    $(function () {

        $('.ref').click(function () {
            $("select[name=version_id]").val($(this).attr('data-value'));
            $('#project').val($(this).attr('data-name'));
            $('#version_id').val($(this).attr('data-value'));

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
