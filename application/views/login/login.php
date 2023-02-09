<div class="container">

   <div class="row">
		<div class="col-lg-4 col-sm-4">

			<div style="text-align: center; margin-top: 10%">
			   
			   <!--
			   <img src="<?= base_url() ?>/assets/images/logo_lart_with_text.jpg" height="100">
			   -->
			   
			   <br>
			   <br>
			   
			</div>
		
			<br>
			
		</div>
	</div>
	
   <div class="row">
		
		<div class="col-lg-4 col-md-6 col-sm-12">
		
		<div class="panel panel-default">

			<div class="panel-heading">
               <h3 class="panel-title"><b>Ingreso al sistema</b></h3>
            </div>

            <div class="panel-body">
               <form role="form" action="<?= $url_auth ?>" method="post" id="form" onsubmit="return validateForm()">
                  <fieldset>
                     <div class="form-group">
                        <input class="form-control"
                        <?php if ((isset($controller)) and ($controller->is_developing_mode())): ?>
                                  placeholder="r2Soft@gmail.com" 
                               <?php else: ?>
                                  placeholder="E-mail" 
                               <?php endif; ?>
                               name="email" 
                               type="" autofocus>
                     </div>
                     <div class="form-group">
                        <input class="form-control" placeholder="Contraseña" name="password" type="password" value="">
                     </div>
                     <div>
                        <p  style="color:black" id="msj">
                           <?= isset($error_string) ? "<div class='error-string alert alert-danger' role='alert'>$error_string</div>" : (is_null($done_change_psw) ? '' : "<div class='error-string alert alert-success' role='alert'>La clave se ha modificado correctamente</div>") ?>
                        </p>
                     </div>
                     <div class="checkbox">
                        <label>
                           <input name="remember" type="checkbox" value="Remember Me">Recordarme
                        </label>
                     </div>
                     <!-- Change this to a button or input when using this as a form -->
                     <input class="btn btn-default" value="Ingresar" type="submit">
                     <!-- <a href="index.html" class="btn btn-lg btn-success btn-block">Login</a> -->
                     <a href="<?= $url_psw_recover ?>">Olvid&oacute; su contraseña ?</a>
                  </fieldset>
               </form>
            </div>
         </div>
		 
		 
		<a data-toggle="modal" data-target="#modal_terminosDeUso" style="cursor:pointer">
			<i class="fa fa-lock"></i>
			Términos de uso.
		</a>
		
		<br>

		<a data-toggle="modal" data-target="#modal_comoCitar" style="cursor:pointer">
			<i class="fa fa-comment"></i>
			Cómo citar.
		</a>

		<br>
		
		<a href="mailto:lart@agro.uba.ar" style="cursor:pointer">
			<i class="fa fa-envelope"></i>
			lart@agro.uba.ar
		</a>

		</div>

		<div class="col-lg-8 col-md-6 col-sm-12">
		
			<div class="panel panel-primary">
			<div class="panel-heading">
			<h3>Sistema de seguimiento forrajero <b>FOCUS</b></h3>
			</div>
			
			<div class="panel-body">
			<p>
			Se trata de un software de gestión de información satelital para observar recursos naturales. 
			<br>
			Estima productividad forrajera o tasa de crecimiento, a partir de combinar datos satelitales y calibraciones hechas en el campo.
			</p>
			</div>
			
		
			</div>
		</div>
		
		<div class="col-lg-8 col-md-6 col-sm-12 white-bg">
		
		<div class="creators_brands text-center">
		<h4>Desarrollado por:</h4>
		
			<a href="#" target="_blank">
				<image src="<?= base_url() ?>/assets/images/brand_crea.png" height=70"/>
			</a>
			
			&nbsp;
			
			<a href="#" target="_blank">
				<image src="<?= base_url() ?>/assets/images/brand_ifeva.png" height=70"/>
			</a>
		
			&nbsp;
			
			<a href="#" target="_blank">
				<image src="<?= base_url() ?>/assets/images/brand_fauba.jpeg" height=70"/>
			</a>
		
			&nbsp;
			
			<a href="#" target="_blank">
				<image src="<?= base_url() ?>/assets/images/brand_inta.gif" height=70"/>
			</a>
		
			
		</div>
		</div>
		
		
		<!-- Brands de financiadores -->
		<div class="col-lg-12 col-sm-12 white-bg">
		
		<br>
		<hr>
		
		<h4>Financiado por:</h4>
		
			<div id="financed_by_brands" class="text-center">
			
			
			<a href="http://www.conicet.gov.ar" target="_blank">
				<image src="<?= base_url() ?>/assets/images/brand_conicet.jpg" height=65"/>
			</a>
			
			&nbsp;
			
			<a href="http://www.uba.ar" target="_blank">
				<image src="<?= base_url() ?>/assets/images/brand_uba.jpeg" height=50"/>
			</a>
			
			&nbsp;
			
			
			<a href="https://www.argentina.gob.ar/ciencia/agencia/la-agencia" target="_blank">
				<image src="<?= base_url() ?>/assets/images/brand_agencia.gif" height=50"/>
			</a>
			
			&nbsp;
			
			
			<a href="http://www.argentina.gob.ar/agroindustria/agricultura-ganaderia-y-pesca" target="_blank">
				<image src="<?= base_url() ?>/assets/images/brand_secretaria.png" height=50"/>
			</a>
			
			&nbsp;
			
			
			<a href="http://www.ipcva.com.ar" target="_blank">
				<image src="<?= base_url() ?>/assets/images/brand_ipcv.jpg" height=50"/>
			</a>
			
			&nbsp;
			

			</div>
		
		</div>


	</div>		
	

	
	<div id="git-commit">
	<?php if ((isset($controller)) and ($controller->is_developing_mode())): ?>
		<?=R2_Abstract_controller::get_last_commit()?>
	<?php endif;?>
	</div>

      
</div>
<!-- End of contaier -->


<!-- Modal "Términos de Uso"-->
<div id="modal_terminosDeUso" class="modal fade" role="dialog">
  <div class="modal-dialog" style="width: 800px">

	<!-- Modal content-->
	<div class="modal-content">
	  <div class="modal-header">
		<button type="button" class="close" data-dismiss="modal">&times;</button>
		<h4 class="modal-title">
			FOCUS - Sistema de Seguimiento Forrajero.
		</h4>
		<h2 class="modal-title">
			 Términos de uso
		</h2>
	  </div>
	  <div class="modal-body">
		<p>
		Este software tiene como único objetivo generar información cuantitativa sobre el estado de los recursos naturales.
		</p>
		
		<p>
		Es un producto desarrollado por un grupo de la FAUBA (ver cita más abajo) como parte de un proyecto conjunto entre la asociación de Consorcios Regionales de Experimentación Agrícola (CREA), 
		 la Facultad de Agronomía de la Universidad de Buenos Aires (FAUBA) y el Instituto Nacional de Tecnología Agropecuaria (INTA). 
	    </p>
		
		<p>
		El desarrollo del software fue también financiado por el entonces Ministerio de Agroindustria de la Nación (actual Secretaría de Agroindustria), 
		 el Instituto de Promoción de la Carne Vacuna Argentina (IPCVA), la Agencia Nacional de Promoción Científica y Tecnológica (ANPCyT), 
		 la Universidad de Buenos Aires (UBA) y el Consejo Nacional de Investigaciones Científicas y Tecnológicas (CONICET). 
		</p>
		
		<p>
		La programación fue hecha por la empresa <a href="http://www.r2software.net/">R2 software</a>. 
		</p>
		
		<p>
		El software gestiona con rigor científico información espacial y temporalmente explícita que proviene de 
		 diferentes sensores remotos satelitales y estudios ecofisiológicos, pero debido a que naturalmente el conocimiento es provisorio, 
		 no puede garantizar la total exactitud, actualización o integridad de los cálculos y resultados proporcionados. 
		</p>
		
		<p>
		No tiene la pretensión y no debe ser interpretado como un generador de recomendaciones biológicas, ambientales y/o agronómicas.
		Entonces, ni los creadores originales ni las instituciones participantes serán responsables por ningún daño o perjuicio resultantes del uso de este software 
		 o de la inhabilidad para utilizarlo, o de la fidelidad de la información generada. 
		</p>
		 
		<p>
		Todo el contenido de este software será protegido por una Licencia Creative Commons o similar.
		</p>
	  </div>
	  <div class="modal-footer">
		<button type="button" class="btn btn-default" data-dismiss="modal">Cerrar</button>
	  </div>
	</div>

  </div>   
</div>   
   
<!-- Modal "como citar" -->
<div id="modal_comoCitar" class="modal fade" role="dialog">
  <div class="modal-dialog">

	<!-- Modal content-->
	<div class="modal-content">
	  <div class="modal-header">
		<button type="button" class="close" data-dismiss="modal">&times;</button>
		<h4 class="modal-title">
			FOCUS - Sistema de Seguimiento Forrajero.
		</h4>
		<h2 class="modal-title">
			 Cómo citar
		</h2>
	  </div>
	  <div class="modal-body">
		<p>
			Irisarri G, Oyarzabal M, Arocena D, Vassallo M, Oesterheld M. Focus: software de gestión de información satelital para observar recursos naturales (versión 2018). LART, IFEVA, Universidad de Buenos Aires, CONICET, Facultad de Agronomía, Buenos Aires, Argentina. URL http://focus.agro.uba.ar.
		</p>
	  </div>
	  <div class="modal-footer">
		<button type="button" class="btn btn-default" data-dismiss="modal">Cerrar</button>
	  </div>
	</div>

  </div>   
</div>   

   
<style>
 #git-commit{
    color: black;
    font-size: 11px;
    font-weight: bold;
    left: 20px;
    bottom: 20px;
    position: fixed;
}

 .white-bg{
	background: white !important;
 }
 
 body{
	background: white !important;
 }
 
 
</style>

<!-- jQuery -->
<script src="<?= base_url() ?>/assets/js/jquery.min.js"></script>

<!-- Bootstrap Core JavaScript -->
<script src="<?= base_url() ?>/assets/js/bootstrap.min.js"></script>

<!-- Metis Menu Plugin JavaScript -->
<script src="<?= base_url() ?>/assets/js/metisMenu.min.js"></script>

<!-- Custom Theme JavaScript -->
<script src="<?= base_url() ?>/assets/js/sb-admin-2.js"></script>

<script>
   function validateForm() {
      var re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      if (!re.test($("#form")[0]["email"].value)) {
         $("#msj")[0].innerHTML = '<div class="error-string alert alert-danger" role="alert">El e-mail no es válido</div>';
         return false;
      }

      var re = /(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{6,}/;

      return true;
   }
</script>

<!--       


