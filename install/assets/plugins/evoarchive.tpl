//<?php
/**
 * evoArchive
 *
 * evoArchive
 *
 * @category    plugin
 * @internal    @events OnDocFormSave,OnManagerMenuPrerender
 * @internal    @modx_category Content
 * @internal    @properties &parent=Родитель;text; &year_template=Шаблон года;text; &alias_visible_year=Год участвует в url;list;false,true;false &month_template=Шаблон месяца;text; &alias_visible_month=Месяц участвует в url;list;false,true;false &donthit=Показывать дочерние ресурсы месяца;list;false,true;false 
 * @internal    @disabled 0
 * @internal    @installset base
 */
if ($modx->event->name == 'OnManagerMenuPrerender') {
	$evo_archive = ['evo_archive', 'main', '<i class="fa fa-cog"></i> Добавить статью',
					'index.php?a=4&pid=' . $parent, 'Добавить статью', '', '', 'main', 0, 100, ''];
	$params['menu']['evo_archive'] = $evo_archive;
	$modx->event->output(serialize($params['menu']));
}
if (($modx->event->name=='OnDocFormSave') && ($_REQUEST['parent']==$parent)){	
	$folders_current = array();
	$months = [	'01'=>'Январь','02'=>'Февраль','03'=>'Март','04'=>'Апрель','05'=>'Май','06'=>'Июнь', '07'=>'Июль','08'=>'Август','09'=>'Сентябрь','10'=>'Октябрь','11'=>'Ноябрь','12'=>'Декабрь'];

	$res = $modx->db->query('Select id,pagetitle from '.$modx->getFullTableName('site_content').' where parent = '.$parent.' and template = '.$year_template);
	while ($row = $modx->db->getRow($res)){
		$folders_current[$row['pagetitle']] = ['id'=>$row['id']];
		$res2 = $modx->db->query('Select id,pagetitle from '.$modx->getFullTableName('site_content').' where parent = '.$row['id'].' and template = '.$month_template);		
		while ($row2 = $modx->db->getRow($res2)){			
			$folders_current[$row['pagetitle']][$row2['pagetitle']] = $row2['id'];	
		}
	}	
	$date = $modx->db->getValue('Select min(createdon) from '.$modx->getFullTableName('site_content').' where parent = '.$parent.' and template!='.$year_template.' and deleted = 0');		
	if (!$date) return;

	$folders_new = [];
	while (date('U',$date) <= time()){
		$year = date('Y',$date);
		$month = date('m',$date);				
		$date = strtotime('+1 MONTH', strtotime(date('d.m.Y',$date)));
		if (!isset($folders_current[$year][$months[$month]])) $folders_new[$year][$month] = $months[$month];		
	}
	$year = date('Y',time());
	$month = date('m',time());				
	$folders_new[$year][$month] = $months[$month];


	if (count($folders_new)){
		foreach($folders_new as $year => $ms){
			if (!isset($folders_current[$year])){
				$doc = new modResource($modx);
				
				$doc->create([
					'pagetitle'=>$year,
					'template'=>$year_template,
					'alias'=>$year,
					'published'=>1,
					'isfolder'=>1,
					'alias_visible'=>$alias_visible_year,
					'parent'=>$parent]);
				
				$parent_id = $doc->save(false, false);
				$folders_current[$year] = ['id'=>$parent_id];
			} else {
				$parent_id = $folders_current[$year]['id'];
			}

			if ((is_array($ms)) && (count($ms))){
				foreach($ms as $m => $name){
					if (!isset($folders_current[$year][$months[$name]])){
						$doc = new modResource($modx);
						$doc->create(							
							['pagetitle'=>$name,
							 'template'=>$month_template,
							 'alias'=>$m,
							 'published'=>1,
							 'isfolder'=>1,
							 'alias_visible'=>$alias_visible_month,
							 'donthit'=>$donthit,
							 'parent'=>$parent_id]
						);
						
						$mid = $doc->save(false, false);
						$folders_current[$year][$m] = $mid;
					}
				}
			}			
		}
	}


	$res = $modx->db->query('Select id,createdon from '.$modx->getFullTableName('site_content').' where parent = '.$parent.' and template!='.$year_template);
	while ($row = $modx->db->getRow($res)){
		$year = date('Y',$row['createdon']);		
		$month = date('m',$row['createdon']);		
		$parent = $folders_current[$year][$month];		
		$modx->db->update(['parent'=>$parent],$modx->getFullTableName('site_content'),'id='.$row['id']);
	}	
}
