<div class="navbar-default sidebar" role="navigation">
    <div class="sidebar-nav navbar-collapse">
        <ul class="nav" id="side-menu">
            <li class="sidebar-search">
            	<!-- 
                <form role="form" action="<?= $url_search ?>" method="post" class="form-horizontal">
                    <div class="input-group custom-search-form">
                        <input type="text" class="form-control autocomplete" placeholder="Search..." id="search" name="search" autocomplete="true">
                        <span class="input-group-btn">
                            <button class="btn btn-default" type="submit">
                                <i class="fa fa-search"></i>
                            </button>
                        </span>
                    </div>
                </form> -->
                <!-- /input-group -->
            </li>

            <!-- Home -->
            <li>
                <a href="<?= base_url() ?>"><i class="fa fa-home fa-fw"></i> Inicio</a>
            </li>
            <?php foreach ($options as $option): ?>
                <li>
                    <a href="#"><?= $option->menu_icon . ' ' . $option->name ?><span class="fa arrow"></span></a>
                    <?php if (!empty($option->childs)): ?>
                        <ul class="nav nav-second-level collapse">
                            <?php foreach ($option->childs as $child): ?>
                                <li>
                                    <a href="<?= site_url(array($child->controller, $child->action)) ?>"><?= $child->menu_icon . ' ' . $child->name ?></a>
                                </li>
                            <?php endforeach ?>
                        </ul>
                    <?php endif ?>
                </li>
            <?php endforeach ?>
        </ul>
    </div>
    <!-- /.sidebar-collapse -->
</div>
<!-- /.navbar-static-side -->
<script type="text/javascript">
    $(function () {

        var ajax_read_dir = '<?= $url_autocomplete ?>';
        $("#search").autocomplete({
            source: function (request, response) {
                $.ajax({
                    url: ajax_read_dir,
                    type: "POST",
                    dataType: "json",
                    data: {q: request.term},
                    success: function (res) {
                        var array = [];

                        for (var i = 0; i < res.length; i++) {
                            array.push(res[i].display);
                        }
                        response(array);
                    }
                });
            },
            minLength: 4
        });
    });
</script>

<style>
    /* highlight results */
    .ui-autocomplete span.hl_results {
        background-color: #ffff66;
    }

    /* scroll results */
    .ui-autocomplete {
        max-height: 250px;
        overflow-y: auto;
        /* prevent horizontal scrollbar */
        /*overflow-x: hidden;*/
        /* add padding for vertical scrollbar */
        padding-right: 5px;
        z-index: 9999 !important;
    }

    .ui-autocomplete li {
        font-size: 13px;
    }

    /* IE 6 doesn't support max-height
    * we use height instead, but this forces the menu to always be this tall
    */
    * html .ui-autocomplete {
        height: 250px;
    }
    #search {
        position: relative;
        z-index: 10000;
    }

</style>