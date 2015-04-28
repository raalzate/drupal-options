#!/bin/bash
target_PWD=$(readlink -f .)
cd ${target_PWD}

PS3='Seleccione una opcion: '
options=("Crear modulo" "Descargar modulo" "Habilitar modulo" "Limpiar cache del portal" "Limpiar cache del menu" "Buscar algo" "Realizar copia de seguridad"  "Salir")
select opt in "${options[@]}"
do
    case $opt in

        "Crear modulo")
           
           echo "Por favor, escriba el nombre del modulo:"
           read NAME
           echo "Por favor, escriba la descripcion del modulo:"
           read DESCRIPTION
           echo "Separe por comas los hook que desea implementar:"
           read HOOKS

           php -r "
           mkdir('$NAME');
           
           \$head = 'name = $NAME
description=$DESCRIPTION
core=7.x
php=5.2.4
package=Custom
version=7.x.1.0';

           \$mod_head = '<?php
/**
* @file
* $NAME.module
*/

';

  

           file_put_contents('$NAME/$NAME.info', \$head);
           file_put_contents('$NAME/$NAME.module', \$mod_head);

           \$tmp_function = '
/**
* implements hook_%s()
*/
 function %s_%s(%s)
 {
 %s
 }

 ';
           function getHooks(\$hook){

            \$mod_head_install = '<?php
/**
* @file
* $NAME.install
*/

';

            \$_hook = array();

             if(\$hook == 'permission') {
                \$_hook[] = array(
                    'name' => 'permission',
                    'params' => '',
                    'file' => 'module',
                    'return' => 'return \$permissions;'
                  );
                 return \$_hook;
             }

             if(\$hook == 'schema') {
                file_put_contents('$NAME/$NAME.install', \$mod_head_install);

                \$_hook[] = array(
                    'name' => 'schema',
                    'params' => '',
                    'file' => 'install',
                    'return' => 'return \$schema;'
                  );
                \$_hook[] = array(
                    'name' => 'install',
                    'params' => '',
                    'file' => 'install',
                    'return' => 'drupal_install_schema(\"$NAME\");'
                  );

                \$_hook[] = array(
                    'name' => 'uninstall',
                    'params' => '',
                    'file' => 'install',
                    'return' => 'drupal_uninstall_schema(\"$NAME\");'
                  );

                 return \$_hook;
             }


             if(\$hook == 'menu') {
                \$_hook[] = array(
                    'name' => 'menu',
                    'params' => '',
                    'file' => 'module',
                    'return' => '

  \$items[\"$NAME\"] = array(
    \"title\" => \"-- TITLE --\",
    \"type\" => MENU_NORMAL_ITEM,
    \"page callback\" => function(){
      return;
    }
  );

  return \$items;
'
                  );

                 return \$_hook;
             }

             if(\$hook == 'form') {

                  \$_hook[] = array(
                    'name' => 'form',
                    'params' => '\$node, &\$form_state',
                    'file' => 'module',
                    'return' => 'return \$form;'
                  );
                  
                  \$_hook[] = array(
                    'name' => 'form_submit',
                    'params' => '\$form, &\$form_state',
                    'file' => 'module',
                    'return' => ''
                  );

                  \$_hook[] = array(
                    'name' => 'form_validate',
                    'params' => '\$form, &\$form_state',
                    'file' => 'module',
                    'return' => 'return TRUE;'
                  );

                  return \$_hook;
             }

              if(\$hook == 'block') {

                  \$_hook[] = array(
                    'name' => 'block_info',
                    'params' => '',
                    'file' => 'module',
                    'return' => 'return \$blocks;'
                  );
                  
                  \$_hook[] = array(
                    'name' => 'block_view',
                    'params' => '\$delta = null',
                    'file' => 'module',
                    'return' => ''
                  );

                  return \$_hook;
             }

             \$_hook[] = array(
               'name' => \$hook,
               'params' => '',
               'file' => 'module',
               'return' => ''
             );
             return \$_hook;

           }//fin function
           
           if('$HOOKS' != '')
           foreach(explode(',', '$HOOKS') as \$hook){
              foreach(getHooks(\$hook) as \$_hook) {
                file_put_contents('$NAME/$NAME.' . \$_hook['file'],
                sprintf(\$tmp_function, \$_hook['name'], '$NAME', \$_hook['name'], \$_hook['params'], \$_hook['return']), 
                FILE_APPEND);
              }
           }
            
           "
           echo "¿Deseas habilitar el modulo (y/n)?"
           read ENABLE
           if [ ENABLE = "y" ]; then
               drush en $NAME
           fi
           break
          ;;

         "Descargar modulo")
			echo "Nombre del modulo"
           read MYMODULE
         	 drush dl --destination=sites/all/modules/contrib $MYMODULE
           echo "¿Deseas habilitar el modulo (y/n)?"
           read ENABLE
           if [ ENABLE = "y" ]; then
               drush en $MYMODULE
           fi
           break
            break
            ;;   
      "Habilitar modulo")
          echo "¿Que modulo deseas habilitar?"
          read MODULEENABLE
          drush en $MODULEENABLE
          break
            ;;    
      "Limpiar cache del menu")
         	drush cc menu
            break
            ;;  
      "Limpiar cache del portal")
          drush cc all
            break
            ;; 
       

		 "Buscar algo")
			echo "¿Que deseas buscar?"
            read QUERY
            
            grep --color -E -rn "$QUERY" *
            break
            ;;
      "Realizar copia de seguridad")
            drush sql-dump --result-file="dump.sql"
            break
            ;;
        "Salir")
            break
            ;;

        *) echo invalid option;;
    esac
done

