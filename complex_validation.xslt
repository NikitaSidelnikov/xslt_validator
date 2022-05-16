<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
	xmlns="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:sch="http://www.w3.org/2001/XMLSchema" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:ДОК="urn:Д001:Делопроизводство:v0.0.1" 
	xmlns:СП1="urn:Д001:С001:ВидыДокументов:v1.0.0" 
	xmlns:ТМ="urn:Д000:ТрансграничнаяМодель:v0.0.1" 
	xmlns:ДМ="urn:Д002:П001:РаботаСПоручением:v0.0.1">
   <xsl:output method="xml" indent="yes" omit-xml-declaration="yes" encoding="utf-8"/>



	<xsl:template match="@*|node()">
		<xsl:if test="name()" >
			<node>
				<xsl:call-template name="template-test" />
			</node>
		</xsl:if>
	</xsl:template>
	
		
	<xsl:template match="/*">
	<validation_proc>
		<xsl:variable name="name" select="document('complex_schema.xsd')/sch:schema/sch:element/@name" />
		
		<xsl:if test="not($name = name())" >
			<xsl:call-template name="inform">
					<xsl:with-param name="message">
						<xsl:text>Root element имеет неверное наименование </xsl:text><xsl:value-of select="name()" />
					</xsl:with-param>
				</xsl:call-template>
		</xsl:if>
		
		<xsl:call-template name="template-test" />
		<xsl:apply-templates select="node()"/>
	</validation_proc>
	</xsl:template>
	
	<xsl:template name="template-test">
		<xsl:variable name="selected_node" select="." />
		<xsl:variable name="element" select="document('complex_schema.xsd')//*[@name = local-name($selected_node)]" />
		<xsl:variable name="element_type" select="$element/@type" />
						
						
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>--Обрабатывается нода - </xsl:text><xsl:value-of select="$element/@name" />
							</xsl:with-param>
						</xsl:call-template>
						
		<xsl:if test="not($element)" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>Обнаружена недопустимая нода - </xsl:text><xsl:value-of select="local-name($selected_node)" />
							</xsl:with-param>
						</xsl:call-template>
		</xsl:if>

		
		
	
		<xsl:variable name="node" select="document('complex_schema.xsd')/*/*[@name = substring-after($element_type, ':')]" />
			<!-- Проверка значения для simpleType-->
		<xsl:if test="'simpleType' = local-name($node)" >
			<xsl:call-template name="check_simpleType" >
				<xsl:with-param name="value" select="text()" />
				<xsl:with-param name="attribution" select="$node/sch:restriction" />
			</xsl:call-template>
		</xsl:if>
		
		
			<!-- Проверка атрибутов для complexType-->
		<xsl:if test="'complexType' = local-name($node)" >
			<!-- 1ая Проверка атрибутов для complexType. Поиск лишних(недопустимых) атрибутов-->
			<xsl:for-each select="$selected_node/@*">
				<xsl:call-template name="check_attribute_2" >
					<xsl:with-param name="child" select="." />
					<xsl:with-param name="child_array" select="$node" />
				</xsl:call-template>
			</xsl:for-each>	
			<!-- 2ая Проверка атрибутов для complexType. Проверка корректности остальных атрибутов-->
			<xsl:for-each select="$node/sch:attribute">
				<xsl:call-template name="check_attribute" >
					<xsl:with-param name="node" select="$selected_node" />
					<xsl:with-param name="attribute" select="." />
				</xsl:call-template>
			</xsl:for-each>		
			
			<!-- Проверка дочерних элементов для complexType-->
			<!-- 1ая Проверка дочерних элементов для complexType. Поиск лишних(недопустимых) дочерних элементов-->
			<xsl:for-each select="$selected_node/*">
				<xsl:call-template name="check_child_2" >
					<xsl:with-param name="child" select="." />
					<xsl:with-param name="child_array" select="$node" />
				</xsl:call-template>
			</xsl:for-each>
			<!-- 2ая Проверка дочерних элементов для complexType. Проверка корректности остальных дочерних элементов-->
			<xsl:for-each select="$node/sch:sequence/sch:element">
				<xsl:call-template name="check_child" >
					<xsl:with-param name="node" select="$selected_node" />
					<xsl:with-param name="child" select="." />					
				</xsl:call-template>
			</xsl:for-each>			
		</xsl:if>
		
		<!-- Проверка кол-ва дочерних элементов для complexType-->
		<xsl:for-each select="$node/sch:sequence/sch:element">
			<xsl:call-template name="check_child_count" >
				<xsl:with-param name="child" select="$selected_node" />
				<xsl:with-param name="child_array" select="." />
			</xsl:call-template>
		</xsl:for-each>
		
		<!-- Проверка порядка дочерних элементов для complexType-->
		<xsl:for-each select="$selected_node/*">
			<xsl:call-template name="check_child_order" >
				<xsl:with-param name="child" select="." />
				<xsl:with-param name="child_array" select="$node" />
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>
	
	
	<!-- Проверка атрибутов для complexType-->
	<xsl:template name="check_attribute">
		<xsl:param name="node" />
		<xsl:param name="attribute" />
		
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>---Проверяется аттрибут - </xsl:text><xsl:value-of select="$attribute/@name" />
							</xsl:with-param>
						</xsl:call-template>
		
		<!-- если атрибут обязателен, проверяем его наличие-->
		<xsl:if test="$attribute/@use = 'required' and not($node/@*[local-name()=$attribute/@name])" >
				<xsl:call-template name="inform">
					<xsl:with-param name="message">
						<xsl:text>Этот обязательный атрибут отсутствует</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
		</xsl:if>
		<!-- если нашли атрибут-->
		<xsl:if test="$node/@*[local-name()=$attribute/@name]" >
			<xsl:variable name="value" select="$node/@*[local-name()=$attribute/@name]" />
			<xsl:variable name="type" select="$attribute/@type" />
			<xsl:variable name="node_sch" select="document('complex_schema.xsd')/*/*[@name = substring-after($type, ':')]" />
			
			<xsl:call-template name="check_simpleType" >
				<xsl:with-param name="value" select="$value" />
				<xsl:with-param name="attribution" select="$node_sch/sch:restriction" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	<!-- 2ая Проверка атрибутов для complexType. Поиск лишних(недопустимых) атрибутов-->
	<xsl:template name="check_attribute_2">
		<xsl:param name="child" />
		<xsl:param name="child_array" />
		
		<xsl:if test="not($child_array//sch:attribute/@name=local-name($child))" >
			<xsl:call-template name="inform">
				<xsl:with-param name="message">
					<xsl:text>Обнаружен недопустимый атрибут для данной ноды - </xsl:text><xsl:value-of select="local-name($child)" />
				</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	
	
		<!-- Проверка дочерних элементов для complexType-->
	<xsl:template name="check_child">
		<xsl:param name="node" />
		<xsl:param name="child" />
		
				<xsl:call-template name="inform">
					<xsl:with-param name="message">
						<xsl:text>---Проверяем дочерний элемент </xsl:text><xsl:value-of select="$child/@name" />
					</xsl:with-param>
				</xsl:call-template>
		
		<!-- проверяем наличие дочерних элементов-->
		<xsl:if test="($child/@minOccurs &gt; 0 or not($child/@minOccurs)) and not($node/*[local-name()=$child/@name])" >
				<xsl:call-template name="inform">
					<xsl:with-param name="message">
						<xsl:text>Этот обязательный элемент отсутствует</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
		</xsl:if>	
	</xsl:template>
	
		<!-- 2ая Проверка дочерних элементов для complexType. Поиск лишних(недопустимых) дочерних элементов-->
	<xsl:template name="check_child_2">
		<xsl:param name="child" />
		<xsl:param name="child_array" />
		
		<xsl:if test="not($child_array/sch:sequence//sch:element/@name=local-name($child))" >
			<xsl:call-template name="inform">
				<xsl:with-param name="message">
					<xsl:text>Обнаружен недопустимый дочерний элемент для данной ноды - </xsl:text><xsl:value-of select="local-name($child)" />
				</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
		<!-- Проверка кол-ва дочерних элементов для complexType-->
	<xsl:template name="check_child_count">
		<xsl:param name="child" />
		<xsl:param name="child_array" />				
		
		<xsl:if test="$child/*[local-name()=$child_array/@name]" >	
			<xsl:variable name="count" select="count($child/*[local-name()=$child_array/@name])" />
		
			<xsl:if test="not($child_array/@minOccurs) and not($child_array/@maxOccurs)" >		
				<xsl:if test="not($count=1)">
					<xsl:call-template name="inform">
						<xsl:with-param name="message">
							<xsl:text>Недопустимое кол-во элемента </xsl:text><xsl:value-of select="$child_array/@name" /><xsl:text> - </xsl:text><xsl:value-of select="count($child/*[local-name()=$child_array/@name])" /><xsl:text>. Допустимо - 1</xsl:text>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:if>
			</xsl:if>
			
			<xsl:if test="$child_array/@minOccurs and not($child_array/@maxOccurs)" >
				<xsl:if test="not($count &gt;= $child_array/@minOccurs and $count &lt;=1)">
					<xsl:call-template name="inform">
						<xsl:with-param name="message">
							<xsl:text>Недопустимое кол-во элемента </xsl:text><xsl:value-of select="$child_array/@name" /><xsl:text> - </xsl:text><xsl:value-of select="count($child/*[local-name()=$child_array/@name])" /><xsl:text>. Допустимо - [</xsl:text><xsl:value-of select="$child_array/@minOccurs" /><xsl:text>; 1]</xsl:text>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:if>
			</xsl:if>
			
			<xsl:if test="not($child_array/@minOccurs) and $child_array/@maxOccurs" >
				<xsl:if test="$child_array/@maxOccurs='unbounded'" >
					<xsl:if test="not($count &gt;= 1)">
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>Недопустимое кол-во элемента </xsl:text><xsl:value-of select="$child_array/@name" /><xsl:text> - </xsl:text><xsl:value-of select="count($child/*[local-name()=$child_array/@name])" /><xsl:text>. Допустимо - [1;unbounded]</xsl:text>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:if>
				</xsl:if>
				<xsl:if test="not($child_array/@maxOccurs='unbounded')" >
					<xsl:if test="not($count &gt;= 1 and $count &lt;=$child_array/@maxOccurs)">
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>Недопустимое кол-во элемента </xsl:text><xsl:value-of select="$child_array/@name" /><xsl:text> - </xsl:text><xsl:value-of select="count($child/*[local-name()=$child_array/@name])" /><xsl:text>. Допустимо - [1;</xsl:text><xsl:value-of select="$child_array/@maxOccurs" /><xsl:text>]</xsl:text>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:if>
				</xsl:if>
			</xsl:if>
			<xsl:if test="$child_array/@minOccurs and $child_array/@maxOccurs" >
				<xsl:if test="$child_array/@maxOccurs='unbounded'" >
					<xsl:if test="not($count &gt;= $child_array/@minOccurs)">
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>Недопустимое кол-во элемента </xsl:text><xsl:value-of select="$child_array/@name" /><xsl:text> - </xsl:text><xsl:value-of select="count($child/*[local-name()=$child_array/@name])" /><xsl:text>. Допустимо - [</xsl:text><xsl:value-of select="$child_array/@minOccurs" /><xsl:text>;unbounded]</xsl:text>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:if>
				</xsl:if>
				<xsl:if test="not($child_array/@maxOccurs='unbounded')" >
					<xsl:if test="not($count &gt;= $child_array/@minOccurs and $count &lt;=$child_array/@maxOccurs)">
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>Недопустимое кол-во элемента </xsl:text><xsl:value-of select="$child_array/@name" /><xsl:text> - </xsl:text><xsl:value-of select="count($child/*[local-name()=$child_array/@name])" /><xsl:text>. Допустимо - [</xsl:text><xsl:value-of select="$child_array/@minOccurs" /><xsl:text>;</xsl:text><xsl:value-of select="$child_array/@maxOccurs" /><xsl:text>]</xsl:text>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:if>
				</xsl:if>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	
		<!-- Проверка порядка дочерних элементов для complexType-->
	<xsl:template name="check_child_order">
		<xsl:param name="child" />
		<xsl:param name="child_array" />
		
		<xsl:variable name="position" select="position()" />
		<!-- Проверяем наличия элемента в xsd-->
		<xsl:if test="$child_array/sch:sequence//sch:element/@name=local-name($child)" >
			<xsl:variable name="xml_node_previous" select="local-name(preceding-sibling::*[1])" />
			<xsl:variable name="xsd_node_previous" select="$child_array/sch:sequence//sch:element[@name=local-name($child)]/preceding-sibling::*[1]" />
			
			<!-- Если был предыдущий xml эдемент (т.е. дочерний не является самым первым в массиве) - продолжаем-->
			<xsl:if test="$xml_node_previous" >
				<!-- Если этот элемент равен предыдущему - игнорируем (нас не интересут элементы с minOcur или maxOcur отличные от 1, если они были предыдущими)-->
				<xsl:if test="not($xml_node_previous = local-name($child))" >	
					<!-- Если предыдущий элемент xml не равен предыдущему элементу xsd (xsd[node; node2]; в xml node2, значит предыдущий должен быть node) или последнее вхождение проверяемого элемента не null (т.е. встречалось ранее), то ошибка-->
					<xsl:if test="not($xml_node_previous = $xsd_node_previous/@name) or $child/preceding-sibling::*[local-name()=local-name($child)]" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>Обнаружено нарушение порядка дочерних элементов - </xsl:text><xsl:value-of select="local-name($child)" /><xsl:text> на позициии </xsl:text><xsl:value-of select="$position" />
							</xsl:with-param>
						</xsl:call-template>
					</xsl:if>
				</xsl:if>
			</xsl:if>			
			<!-- Если не было предыдущего xml эдемента-->
			<xsl:if test="not($xml_node_previous)" >
				<xsl:if test="not(local-name($child) = $child_array/sch:sequence/sch:element[1]/@name)" >
					<xsl:call-template name="inform">
						<xsl:with-param name="message">
							<xsl:text>Обнаружено нарушение порядка дочерних элементов - </xsl:text><xsl:value-of select="local-name($child)" /><xsl:text> на позициии </xsl:text><xsl:value-of select="$position" />
						</xsl:with-param>
					</xsl:call-template>
				</xsl:if>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	
	
	<!-- Проверка значения для simpleType-->
	<xsl:template name="check_simpleType">
		<xsl:param name="value" />
		<xsl:param name="attribution" />
		
		<xsl:call-template name="check_pattern" >
				<xsl:with-param name="value" select="$value" />
				<xsl:with-param name="pattern" select="$attribution/sch:pattern/@value" />
			</xsl:call-template>
			<xsl:call-template name="check_minLength" >
				<xsl:with-param name="value" select="$value" />
				<xsl:with-param name="minLength" select="$attribution/sch:minLength/@value" />
			</xsl:call-template>
			<xsl:call-template name="check_maxLength" >
				<xsl:with-param name="value" select="$value" />
				<xsl:with-param name="maxLength" select="$attribution/sch:maxLength/@value" />
			</xsl:call-template>
			<xsl:call-template name="check_maxInclusive" >
				<xsl:with-param name="value" select="$value" />
				<xsl:with-param name="type" select="$attribution/@base" />
				<xsl:with-param name="maxInclusive" select="$attribution/sch:maxInclusive/@value" />
			</xsl:call-template>
			<xsl:call-template name="check_minInclusive" >
				<xsl:with-param name="value" select="$value" />
				<xsl:with-param name="type" select="$attribution/@base" />
				<xsl:with-param name="minInclusive" select="$attribution/sch:minInclusive/@value" />
			</xsl:call-template>	
	</xsl:template>
	
	<!-- Проверка pattern (regexp и pattern - разные вещи. Тут, к сожалению, regexp)-->
	<xsl:template name="check_pattern">
		<xsl:param name="value" />
		<xsl:param name="pattern" />
		
		<xsl:if test="$pattern">
			<xsl:if test="not($value[matches(., $pattern)])" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>Паттерн не верный</xsl:text>
							</xsl:with-param>
						</xsl:call-template>
			</xsl:if>
		</xsl:if>		
	</xsl:template>
	
		<!-- Проверка minLength-->
	<xsl:template name="check_minLength">
		<xsl:param name="value" />
		<xsl:param name="minLength" />
		
		<xsl:if test="$minLength">
			<xsl:if test="not(string-length($value) &gt;= $minLength)" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>minLength не верный</xsl:text>
							</xsl:with-param>
						</xsl:call-template>
			</xsl:if>		
		</xsl:if>
	</xsl:template>
	
			<!-- Проверка maxLength-->
	<xsl:template name="check_maxLength">
		<xsl:param name="value" />
		<xsl:param name="maxLength" />
		
		<xsl:if test="$maxLength">
		<xsl:if test="not(string-length($value) &lt;= $maxLength)" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>maxLength не верный</xsl:text>
							</xsl:with-param>
						</xsl:call-template>
			</xsl:if>	
		</xsl:if>			
	</xsl:template>
	
			<!-- Проверка maxInclusive-->
	<xsl:template name="check_maxInclusive">
		<xsl:param name="value" />
		<xsl:param name="type" />
		<xsl:param name="maxInclusive" />
		
		<xsl:if test="$maxInclusive">
			<xsl:choose>
				<xsl:when test="contains($type, 'date')" >
					<xsl:if test="not(number(translate($value,':T-','0')) &lt;= number(translate($maxInclusive,':T-','0')))" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>maxInclusive не верный</xsl:text>
							</xsl:with-param>
						</xsl:call-template>	
					</xsl:if>	
				</xsl:when>		
				<xsl:otherwise>
					<xsl:if test="not($value &lt;= $maxInclusive)" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>maxInclusive не верный</xsl:text>
							</xsl:with-param>
						</xsl:call-template>	
					</xsl:if>	
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	
			<!-- Проверка minInclusive-->
	<xsl:template name="check_minInclusive">
		<xsl:param name="value" />
		<xsl:param name="type" />
		<xsl:param name="minInclusive" />
		
		<xsl:if test="$minInclusive">
			<xsl:choose>
				<xsl:when test="contains($type, 'date')" >
					<xsl:if test="not(number(translate($value,':T-','0')) &gt;= number(translate($minInclusive,':T-','0')))" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>minInclusive не верный</xsl:text>
							</xsl:with-param>
						</xsl:call-template>	
					</xsl:if>	
				</xsl:when>	
				<xsl:otherwise>
					<xsl:if test="not($value &gt;= $minInclusive)" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>minInclusive не верный</xsl:text>
							</xsl:with-param>
						</xsl:call-template>	
					</xsl:if>	
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>	
	</xsl:template>
	
	
	
	<xsl:template name="inform">
		<xsl:param name="message" />
		
		<message>
			<xsl:value-of select="$message" />
		</message>	
	</xsl:template>
	
</xsl:stylesheet>