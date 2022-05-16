<xsl:stylesheet version="1.0" 
	xmlns="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:sch="http://www.w3.org/2001/XMLSchema" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:ДОК="urn:Д001:Делопроизводство:v0.0.1" 
	xmlns:СП1="urn:Д001:С001:ВидыДокументов:v1.0.0" 
	xmlns:ТМ="urn:Д000:ТрансграничнаяМодель:v0.0.1" 
	xmlns:ДМ="urn:Д002:П001:РаботаСПоручением:v0.0.1">
   <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>



	<xsl:template match="*">
		<values>
			<xsl:call-template name="template-test" />
		</values>
	</xsl:template>
	
	<xsl:template name="template-test">
		<xsl:variable name="name" select="document('simple_schema.xsd')/sch:schema/sch:element/@name" />
		<xsl:variable name="type" select="document('simple_schema.xsd')/sch:schema/sch:element/@type" />
		
		<xsl:if test="not($name = name())" >
			<xsl:call-template name="inform">
					<xsl:with-param name="message">
						<xsl:text>Root element имеет неверное наименование </xsl:text><xsl:value-of select="name()" />
					</xsl:with-param>
				</xsl:call-template>
		</xsl:if>

		
		<xsl:variable name="node" select="document('simple_schema.xsd')/*/*[@name = substring-after($type, ':')]" />
			<!-- Проверка значения-->
		<xsl:if test="'simpleType' = local-name($node)" >
			<xsl:call-template name="check" >
				<xsl:with-param name="value" select="text()" />
				<xsl:with-param name="attribution" select="$node/sch:restriction" />
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	
	<!-- Проверка значения-->
	<xsl:template name="check">
		<xsl:param name="value" />
		<xsl:param name="attribution" />
		
		<xsl:call-template name="check_pattern" >
				<xsl:with-param name="value" select="text()" />
				<xsl:with-param name="pattern" select="$attribution/sch:pattern/@value" />
			</xsl:call-template>
			<xsl:call-template name="check_minLength" >
				<xsl:with-param name="value" select="text()" />
				<xsl:with-param name="minLength" select="$attribution/sch:minLength/@value" />
			</xsl:call-template>
			<xsl:call-template name="check_maxLength" >
				<xsl:with-param name="value" select="text()" />
				<xsl:with-param name="maxLength" select="$attribution/sch:maxLength/@value" />
			</xsl:call-template>
			<xsl:call-template name="check_maxInclusive" >
				<xsl:with-param name="value" select="text()" />
				<xsl:with-param name="type" select="$attribution/@base" />
				<xsl:with-param name="maxInclusive" select="$attribution/sch:maxInclusive/@value" />
			</xsl:call-template>
			<xsl:call-template name="check_minInclusive" >
				<xsl:with-param name="value" select="text()" />
				<xsl:with-param name="type" select="$attribution/@base" />
				<xsl:with-param name="minInclusive" select="$attribution/sch:minInclusive/@value" />
			</xsl:call-template>	
	</xsl:template>
	
	<!-- Проверка pattern (regexp и pattern - разные вещи. Тут, к сожалению, regexp)-->
	<xsl:template name="check_pattern">
		<xsl:param name="value" />
		<xsl:param name="pattern" />
		
		<xsl:if test="$pattern">
			<xsl:if test="$value[matches(., $pattern)]" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>Паттерн верный</xsl:text>
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
			<xsl:if test="string-length($value) &gt;= $minLength" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>minLength верный</xsl:text>
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
		<xsl:if test="string-length($value) &lt;= $maxLength" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>maxLength верный</xsl:text>
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
					<xsl:if test="number(translate($value,':T-','0')) &lt;= number(translate($maxInclusive,':T-','0'))" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>maxInclusive верный</xsl:text>
							</xsl:with-param>
						</xsl:call-template>	
					</xsl:if>	
				</xsl:when>		
				<xsl:otherwise>
					<xsl:if test="$value &lt;= $maxInclusive" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>maxInclusive верный</xsl:text>
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
					<xsl:if test="number(translate($value,':T-','0')) &gt;= number(translate($minInclusive,':T-','0'))" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>minInclusive верный</xsl:text>
							</xsl:with-param>
						</xsl:call-template>	
					</xsl:if>	
				</xsl:when>	
				<xsl:otherwise>
					<xsl:if test="$value &gt;= $minInclusive" >
						<xsl:call-template name="inform">
							<xsl:with-param name="message">
								<xsl:text>minInclusive верный</xsl:text>
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
			<xsl:text>ERR MESS: </xsl:text>
			<xsl:value-of select="$message" />
		</message>	
	</xsl:template>
	
</xsl:stylesheet>