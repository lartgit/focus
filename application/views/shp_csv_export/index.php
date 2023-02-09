<style type="text/css">
    .list-group-item {
        cursor: pointer;
    }
    .list-group-item:hover {
        background-color: lightgray;
    }
</style>
<div class="row">
    <div class="col-md-12">
        <h3><?= lang("Descarga de archivos") ?></h3>
    </div>
</div>
<div class="row">
    <div class="col-md-12">
        <?php if (isset($url_back)): ?>
            <a class="btn btn-primary btn-sm" href="<?= $url_back ?>">
                <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
            </a>
        <?php endif; ?>

    </div>
</div>

<div class="row">
    <div class="col-md-2 col-md-offset-5">
        <button class="btn btn-primary col-md-12" id="download_dir"><?=lang('Descargar Directorio')?></button>
    </div>
	<div class="col-md-10 col-md-offset-1">
        <div class="panel list-group" id="list_data">
        </div>
	</div>
</div>

<script>
var tag_i_fi = '<i class="fa fa-file-text"></i> ';
var tag_i_fo = '<i class="fa fa-folder"></i> ';
var current_dir = '<?=$current_dir?$current_dir:'/'?>';

$(function() {
    dir_nav();

    $('#download_dir').click(download_dir);
})

function dir_nav(e){
  // e.preventDefault();
    var ajax_read_dir = '<?=$url_ajax_read_dir ?>';
        var row_val = $(this).attr('data-name');
        if (typeof(row_val) === 'undefined') {
            row_val = '';
        }

        if (this.id != 'btn-sel') {
            if (row_val == 'back') {
                new_current_dir = current_dir.split('/');
                new_current_dir.pop();
                new_current_dir.pop();
                current_dir = new_current_dir.join('/') + '/';
            }else{
                current_dir = current_dir + row_val + '/';
            }
        }
        
        $.ajax({
        url: ajax_read_dir,
        data: {folder: current_dir},
        type: "POST",
        dataType: "json",
            beforeSend: function () {
               // $("#square").html('Cargando');
            },
            error: function (res) {
               // $("#result").html("Ocurrio un error url: " + ajax_read_dir).fadeIn("slow");
            },
            success: function (res) {
                $('#list_data').html('');
                $('#list_data').append('<div class="list-group-item dir" data-name="back">..</div>');
                for (index = 0; index < res.length; ++index) {
                    if (res[index].type == 'dir') {
                        $('#list_data').append('<div class="list-group-item dir" data-name="'+ res[index].name +'">' + tag_i_fo + res[index].name + '</div>');
                    }else{
                        $('#list_data').append('<div class="list-group-item file" data-name="'+ res[index].name +'">' + tag_i_fi + res[index].name +'</div>');
                    }
                }
                $('div.dir').click(dir_nav);
                $('div.file').click(set_path);

            }
        }); 
}

function download_dir(e) {
    $('#download_link').attr('href', '<?=$url_download_dir?>/?current_dir='+encodeURI(current_dir))[0].click();
}

function set_path(e){
    e.preventDefault();
    var row_val = $(this).attr('data-name');    
    $('#download_link').attr('href', '<?=base_url(EXPORTING_DIR_RESULT)?>'+current_dir+row_val)[0].click();
}
</script>
<a id="download_link" style="display: none;" target="_blank"></a>
