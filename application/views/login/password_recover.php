
<div class="container">
    <div class="row">
        <div class="col-md-4 col-md-offset-4">
            <div style="text-align: center; margin-top: 10%">
                <img src="<?= base_url() ?>/assets/images/logo_lart_with_text.jpg" height="100">
            </div>
            <div class="login-panel panel panel-default" style="margin-top: 10%">
                <div class="panel-heading">
                    <h3 class="panel-title">Recuperar clave</h3>
                </div>
                <div class="panel-body">
                    <form role="form" action="<?= $url_psw_recover_submit ?>" method="post">
                        <fieldset>
                            <div class="form-group">
                                <input class="form-control" placeholder="E-mail" name="email" type="email" value="" <?php echo isset($disabled_all) ? 'disabled' : '' ?>>
                            </div>

                            <div>
                                <p  style="color:black" id="msj">
                                    <?= isset($error_string) ? isset($disabled_all) ? "<div class='error-string alert alert-success' role='alert'>$error_string</div>" : "<div class='error-string alert alert-danger' role='alert'>$error_string</div>" : '' ?>
                                </p>
                            </div>
                            <div class="btn">
                                <input class="form-control" placeholder="" name="" type="submit" value="Recuperar" <?php echo isset($disabled_all) ? 'disabled' : '' ?>>
                            </div>
                            <!-- Change this to a button or input when using this as a form -->
                            <!--  <a href="index.html" class="btn btn-lg btn-success btn-block">Login</a>-->
                            <a href="<?= $_url_login ?>">Volver</a>
                        </fieldset>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- jQuery -->
<script src="../bower_components/jquery/dist/jquery.min.js"></script>

<!-- Bootstrap Core JavaScript -->
<script src="../bower_components/bootstrap/dist/js/bootstrap.min.js"></script>

<!-- Metis Menu Plugin JavaScript -->
<script src="../bower_components/metisMenu/dist/metisMenu.min.js"></script>

<!-- Custom Theme JavaScript -->
<script src="../dist/js/sb-admin-2.js"></script>
