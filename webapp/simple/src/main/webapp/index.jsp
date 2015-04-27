<html>
<body>
<h2>Hello World!</h2>
<%@ page import = "java.util.*" %>
<b>Parameters:</b><br>
<%
  Enumeration paramsList = request.getParameterNames();
  out.println("<ul>");
  while( paramsList.hasMoreElements() )
  {
    String paramName = paramsList.nextElement().toString();
    String[] paramValues = request.getParameterValues( paramName );
    if ( paramValues != null )
    {
      if ( paramValues.length == 1 )
      {
  		out.println( "<li>" );
        out.println( paramName + " = " + request.getParameter( paramName ) );
        out.println("</li>");
      }
      else
      {
        for( int i = 0; i < paramValues.length; i++ )
        {
          out.println( "<li>" );
          out.println( paramName + "[ " + "] = " + paramValues[i]+"" );
          out.println( "</li>" );
        }
      }
    }
    else
    {
      out.println( "<li>" );
      out.println( paramName + " = null<br>" );
      out.println("</li>");
    }
  }
  out.println("</ul>");
%>
<b>Attributes:</b><br>
<%  
  Enumeration attributesList = request.getAttributeNames();
  out.println("<ul>");
  while( attributesList.hasMoreElements() )
  {
    String attrName = attributesList.nextElement().toString();
    Object attrValue = request.getAttribute(attrName);
    out.println( "<li>" );
    out.println( attrName + " = " + attrValue + "<br>" );
    out.println("</li>");
  }
  String[] shibAttrs = { 
		  "entitlement", "unscoped-affiliation"
     };
  for( int i = 0; i < shibAttrs.length; i ++ )
  {
	  String attrName = shibAttrs[i];
	  Object attrValue = request.getAttribute(shibAttrs[i]);
      out.println( "<li>" );
      out.println( attrName + " = " + attrValue + "<br>" );
      out.println("</li>");
  }
%>
</body>
</html>
