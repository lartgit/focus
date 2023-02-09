<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

require_once APPPATH . "/third_party/PHPExcel.php";

/**
 * class Php_Excel
 * @author axelbayerl
 */
class Php_Excel extends PHPExcel {

    private $colorSrcColumns = array();
    private $colorDstColumns = array();
    private $objPHPExcel = NULL;
    private $objReader  = NULL;

    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Carga un template para que se puedan inertar valores. Atencion a las cosas que PHPExcel soporta.
     * @param type $file
     */
    function loadTemplate($file)
    {
        $this->objPHPExcel = PHPExcel_IOFactory::load($file);
    }

    /**
     * Setea una hoja como activa. Wrapper para el objeto interno
     * @param type $sheet
     */
    function setActiveSheetIndexByName($sheet = '')
    {
        $this->objPHPExcel->setActiveSheetIndexByName($sheet);
    }

    /**
     * Esta funcion establece que columna ($colorColumn) pinta que otra columna ($destColumn).
     * Los indices son 0-based del array que se pasa a writeArray.
     *
     * @param int $colorColumn
     * @param int $destColumn
     * @author axelbayerl
     */
    function setColorColumn($colorColumn, $destColumn)
    {
        $this->colorSrcColumns[$colorColumn] = TRUE;
        $this->colorDstColumns[$destColumn] = $colorColumn;
    }

    /**
     * Esta funcion establece que columna ($colorColumn) pinta que otra columna ($destColumn).
     * Los indices son las propiedades de los objetos que se pasan a writeObjects.
     *
     * @param string $colorColumn
     * @param string $destColumn
     * @author axelbayerl
     */
    function setColorProperty($colorProperty, $destColumn)
    {
        $this->colorDstColumns[$destColumn] = $colorProperty;
    }

    /**
     *
     * @param array(array(...)) $dataArray
     * @param int $fromRow
     * @param int $fromColumn
     * @author axelbayerl
     */
    function writeArray($dataArray, $fromRow = 0, $fromColumn = 0)
    {
        foreach ($dataArray as $numRow => $dataRow) {
            $colsSkipped = 0;
            $numCol = 0;
            foreach ($dataRow as $dataCell) {
                // Ignoro las columnas de colores
                if (key_exists($numCol, $this->colorSrcColumns)) {
                    $colsSkipped++;
                    continue;
                }
                
                $this->objPHPExcel->getActiveSheet()
                        ->setCellValueByColumnAndRow($fromColumn + $numCol - $colsSkipped, $fromRow + $numRow + 1, $dataCell);

                // Si esta columna tiene un color asociado, lo aplico
                if (key_exists($numCol, $this->colorDstColumns) && isset($dataRow[$this->colorDstColumns[$numCol]])) {
                    $this->objPHPExcel->getActiveSheet()
                            ->getStyleByColumnAndRow($fromColumn + $numCol - $colsSkipped, $fromRow + $numRow + 1)
                            ->getFill()
                            ->setFillType(PHPExcel_Style_Fill::FILL_SOLID);
                    $this->objPHPExcel->getActiveSheet()
                            ->getStyleByColumnAndRow($fromColumn + $numCol - $colsSkipped, $fromRow + $numRow + 1)
                            ->getFill()
                            ->getStartColor()
                            ->setRGB($dataRow[$this->colorDstColumns[$numCol]]);
                }
                $numCol++;
            }

        }
    }

    /**
     *
     * @param array(Objects) $objectArray
     * @param array(string) $propertiesToOutput
     * @param int $fromRow
     * @param int $fromColumn
     * @author axelbayerl
     */
    function writeObjects($objectArray, $propertiesToOutput = array(), $fromRow = 0, $fromColumn = 0)
    {
        foreach ($objectArray as $numRow => $objectRow) {
            foreach ($propertiesToOutput as $numCol => $property) {
                $this->objPHPExcel->getActiveSheet()
                        ->setCellValueByColumnAndRow($fromColumn + $numCol,
                                                     $fromRow    + $numRow + 1,
                                                     isset($objectRow->$property)?$objectRow->$property:'');

                //Si esta columna tiene un color asociado, lo aplico
                if (key_exists($property, $this->colorDstColumns) && isset($objectRow->{$this->colorDstColumns[$property]})) {
                    $this->objPHPExcel->getActiveSheet()
                            ->getStyleByColumnAndRow($fromColumn + $numCol, $fromRow + $numRow + 1)
                            ->getFill()
                            ->setFillType(PHPExcel_Style_Fill::FILL_SOLID);
                    $this->objPHPExcel->getActiveSheet()
                            ->getStyleByColumnAndRow($fromColumn + $numCol, $fromRow + $numRow + 1)
                            ->getFill()
                            ->getStartColor()
                            ->setRGB($objectRow->{$this->colorDstColumns[$property]});
                }
            }
        }
    }

    /**
     * funcion que envia a salida estandard el resultado del XLS
     * si no se proporciona $file no se envían las cabeceras.
     * Útil si se usa junto a Ajax
     * @param type $filename
     */
    function save($filename = NULL)
    {
        if (!is_null($filename)) {
            header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'); //mime type
            header("Content-Disposition: attachment;filename=\"$filename\""); //tell browser what's the file name
            header('Cache-Control: max-age=0'); //no cache
        }

        $objWriter = PHPExcel_IOFactory::createWriter($this->objPHPExcel, 'Excel2007');
        //force user to download the Excel file without writing it to server's HD
        $objWriter->save('php://output');
    }

    /**
     * funcion que envia a salida estandard el resultado del XLS
     * si no se proporciona $file no se envían las cabeceras.
     * Útil si se usa junto a Ajax
     * @param type $fullpath del archivo
     */
    function readFile($file)
    {
        
        $this->objReader = new PHPExcel_Reader_Excel2007();
        $this->objReader->setReadDataOnly(false);
        $this->objPHPExcel = $this->objReader->load($file);
        $sheetData = $this->objPHPExcel->getActiveSheet()->toArray(null,true,true,false);
        
        return $sheetData;

    }



}
