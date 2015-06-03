package ch.furthermore.demo;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;
import java.util.UUID;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.ResultSetExtractor;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class WelcomeController {
	@Autowired
	private JdbcTemplate jdbcTemplate;
	
	private static String myId;
	
	@PostConstruct
	public void generateId() {
		if (myId == null) {
			myId = UUID.randomUUID().toString();
		}
	}
	
	@RequestMapping("/")
	public String welcome(Map<String, Object> model, 
			@RequestParam(value="cmd", required=false) String cmd, 
			@RequestParam(value="param", required=false) String param) 
	{
		if ("sleep".equals(cmd) && param != null) {
			execute("delete from message where msgkey='sleepmillis'");
			execute("insert into message(msgkey,msg) values('sleepmillis','" + Long.parseLong(param) + "')");
		}
		
		long sleep = Long.parseLong(query("select msg from message where msgkey='sleepmillis'", "0"));
		
		model.put("welcomeMessage", "Server: " + myId 
				+ ", Message: " + query("select msg from message where msgkey='hello'", "Hi (NOT from DB)")
				+ ", Sleep: " + sleep + " (ms)");
		
		try {
			Thread.sleep(sleep);
		} catch (InterruptedException e) {
			throw new RuntimeException(e);
		}
		
		return "welcome";
	}

	private void execute(String sql) {
		jdbcTemplate.execute(sql);
	}
	
	private String query(String sql, String fallback) {
		String result = jdbcTemplate.query(sql,  new SingleStringResultExtractor());
		return result == null ? fallback : result;
	}
	
	static class SingleStringResultExtractor implements ResultSetExtractor<String> {
		@Override
		public String extractData(ResultSet r) throws SQLException, DataAccessException {
			return r.next() ? r.getString(1) : null;
		}
	}
}
